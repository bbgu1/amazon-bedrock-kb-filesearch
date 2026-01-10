"""
Store Management API Lambda Handler

Provides CRUD operations for store entities with DynamoDB persistence.
"""

import json
import os
import re
from datetime import datetime
from typing import Dict, Any, Optional
import boto3
from botocore.exceptions import ClientError


# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE_NAME')
table = dynamodb.Table(table_name) if table_name else None


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler for Store Management API.
    Routes requests to appropriate CRUD operation handlers.
    """
    try:
        http_method = event.get('httpMethod', '')
        path = event.get('path', '')
        path_parameters = event.get('pathParameters') or {}
        
        # Route to appropriate handler
        if http_method == 'POST' and path == '/stores':
            return create_store(event)
        elif http_method == 'GET' and 'store_id' in path_parameters:
            return get_store(path_parameters['store_id'])
        elif http_method == 'PUT' and 'store_id' in path_parameters:
            return update_store(path_parameters['store_id'], event)
        elif http_method == 'DELETE' and 'store_id' in path_parameters:
            return delete_store(path_parameters['store_id'])
        else:
            return error_response(400, 'INVALID_REQUEST', 'Invalid request path or method')
            
    except Exception as e:
        log_error('lambda_handler', None, str(e))
        return error_response(500, 'INTERNAL_ERROR', 'An unexpected error occurred')


def create_store(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Create a new store.
    POST /stores
    """
    operation_start = datetime.utcnow()
    
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        
        # Validate required fields
        store_id = body.get('store_id')
        if not store_id:
            return error_response(400, 'INVALID_REQUEST', 'store_id is required')
        
        # Validate store_id format (alphanumeric, hyphens, underscores)
        if not re.match(r'^[a-zA-Z0-9_-]+$', store_id):
            return error_response(
                400, 
                'INVALID_REQUEST', 
                'store_id must contain only alphanumeric characters, hyphens, and underscores'
            )
        
        name = body.get('name')
        if not name:
            return error_response(400, 'INVALID_REQUEST', 'name is required')
        
        # Prepare store item
        timestamp = datetime.utcnow().isoformat() + 'Z'
        store_item = {
            'store_id': store_id,
            'name': name,
            'description': body.get('description', ''),
            'created_at': timestamp,
            'updated_at': timestamp,
            'metadata': body.get('metadata', {})
        }
        
        # Add optional s3_sync_config if provided
        if 's3_sync_config' in body:
            store_item['s3_sync_config'] = body['s3_sync_config']
        
        # Check if store already exists
        try:
            response = table.get_item(Key={'store_id': store_id})
            if 'Item' in response:
                return error_response(409, 'STORE_ALREADY_EXISTS', f'Store with id {store_id} already exists')
        except ClientError as e:
            log_error('create_store', store_id, f'Error checking existing store: {str(e)}')
            return error_response(500, 'INTERNAL_ERROR', 'Failed to check existing store')
        
        # Create store in DynamoDB
        try:
            table.put_item(Item=store_item)
        except ClientError as e:
            log_error('create_store', store_id, f'DynamoDB error: {str(e)}')
            return error_response(500, 'INTERNAL_ERROR', 'Failed to create store')
        
        # Log success
        duration_ms = (datetime.utcnow() - operation_start).total_seconds() * 1000
        log_info('create_store', store_id, 'Store created successfully', duration_ms)
        
        return success_response(201, store_item)
        
    except json.JSONDecodeError:
        return error_response(400, 'INVALID_REQUEST', 'Invalid JSON in request body')
    except Exception as e:
        log_error('create_store', None, str(e))
        return error_response(500, 'INTERNAL_ERROR', 'An unexpected error occurred')


def get_store(store_id: str) -> Dict[str, Any]:
    """
    Retrieve a store by ID.
    GET /stores/{store_id}
    """
    operation_start = datetime.utcnow()
    
    try:
        response = table.get_item(Key={'store_id': store_id})
        
        if 'Item' not in response:
            return error_response(404, 'STORE_NOT_FOUND', f'Store with id {store_id} not found')
        
        # Log success
        duration_ms = (datetime.utcnow() - operation_start).total_seconds() * 1000
        log_info('get_store', store_id, 'Store retrieved successfully', duration_ms)
        
        return success_response(200, response['Item'])
        
    except ClientError as e:
        log_error('get_store', store_id, f'DynamoDB error: {str(e)}')
        return error_response(500, 'INTERNAL_ERROR', 'Failed to retrieve store')
    except Exception as e:
        log_error('get_store', store_id, str(e))
        return error_response(500, 'INTERNAL_ERROR', 'An unexpected error occurred')


def update_store(store_id: str, event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Update an existing store.
    PUT /stores/{store_id}
    """
    operation_start = datetime.utcnow()
    
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        
        # Check if store exists
        try:
            response = table.get_item(Key={'store_id': store_id})
            if 'Item' not in response:
                return error_response(404, 'STORE_NOT_FOUND', f'Store with id {store_id} not found')
            
            existing_store = response['Item']
        except ClientError as e:
            log_error('update_store', store_id, f'Error checking existing store: {str(e)}')
            return error_response(500, 'INTERNAL_ERROR', 'Failed to check existing store')
        
        # Prepare update expression
        update_expression_parts = []
        expression_attribute_values = {}
        expression_attribute_names = {}
        
        # Update timestamp
        timestamp = datetime.utcnow().isoformat() + 'Z'
        update_expression_parts.append('#updated_at = :updated_at')
        expression_attribute_names['#updated_at'] = 'updated_at'
        expression_attribute_values[':updated_at'] = timestamp
        
        # Update name if provided
        if 'name' in body:
            update_expression_parts.append('#name = :name')
            expression_attribute_names['#name'] = 'name'
            expression_attribute_values[':name'] = body['name']
        
        # Update description if provided
        if 'description' in body:
            update_expression_parts.append('#description = :description')
            expression_attribute_names['#description'] = 'description'
            expression_attribute_values[':description'] = body['description']
        
        # Update metadata if provided
        if 'metadata' in body:
            update_expression_parts.append('#metadata = :metadata')
            expression_attribute_names['#metadata'] = 'metadata'
            expression_attribute_values[':metadata'] = body['metadata']
        
        # Update s3_sync_config if provided
        if 's3_sync_config' in body:
            update_expression_parts.append('#s3_sync_config = :s3_sync_config')
            expression_attribute_names['#s3_sync_config'] = 's3_sync_config'
            expression_attribute_values[':s3_sync_config'] = body['s3_sync_config']
        
        # Perform update
        update_expression = 'SET ' + ', '.join(update_expression_parts)
        
        try:
            response = table.update_item(
                Key={'store_id': store_id},
                UpdateExpression=update_expression,
                ExpressionAttributeNames=expression_attribute_names,
                ExpressionAttributeValues=expression_attribute_values,
                ReturnValues='ALL_NEW'
            )
            
            updated_store = response['Attributes']
            
        except ClientError as e:
            log_error('update_store', store_id, f'DynamoDB error: {str(e)}')
            return error_response(500, 'INTERNAL_ERROR', 'Failed to update store')
        
        # Log success
        duration_ms = (datetime.utcnow() - operation_start).total_seconds() * 1000
        log_info('update_store', store_id, 'Store updated successfully', duration_ms)
        
        return success_response(200, updated_store)
        
    except json.JSONDecodeError:
        return error_response(400, 'INVALID_REQUEST', 'Invalid JSON in request body')
    except Exception as e:
        log_error('update_store', store_id, str(e))
        return error_response(500, 'INTERNAL_ERROR', 'An unexpected error occurred')


def delete_store(store_id: str) -> Dict[str, Any]:
    """
    Delete a store.
    DELETE /stores/{store_id}
    """
    operation_start = datetime.utcnow()
    
    try:
        # Check if store exists
        try:
            response = table.get_item(Key={'store_id': store_id})
            if 'Item' not in response:
                return error_response(404, 'STORE_NOT_FOUND', f'Store with id {store_id} not found')
        except ClientError as e:
            log_error('delete_store', store_id, f'Error checking existing store: {str(e)}')
            return error_response(500, 'INTERNAL_ERROR', 'Failed to check existing store')
        
        # Delete store from DynamoDB
        try:
            table.delete_item(Key={'store_id': store_id})
        except ClientError as e:
            log_error('delete_store', store_id, f'DynamoDB error: {str(e)}')
            return error_response(500, 'INTERNAL_ERROR', 'Failed to delete store')
        
        # Log success
        duration_ms = (datetime.utcnow() - operation_start).total_seconds() * 1000
        log_info('delete_store', store_id, 'Store deleted successfully', duration_ms)
        
        return success_response(204, None)
        
    except Exception as e:
        log_error('delete_store', store_id, str(e))
        return error_response(500, 'INTERNAL_ERROR', 'An unexpected error occurred')


def success_response(status_code: int, data: Optional[Any]) -> Dict[str, Any]:
    """Generate a successful API response."""
    response = {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        }
    }
    
    if data is not None and status_code != 204:
        response['body'] = json.dumps(data)
    else:
        response['body'] = ''
    
    return response


def error_response(status_code: int, error_code: str, message: str, details: Optional[Dict] = None) -> Dict[str, Any]:
    """Generate an error API response."""
    error_body = {
        'error': {
            'code': error_code,
            'message': message
        }
    }
    
    if details:
        error_body['error']['details'] = details
    
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        },
        'body': json.dumps(error_body)
    }


def log_info(operation: str, store_id: Optional[str], message: str, duration_ms: Optional[float] = None):
    """Log informational message to CloudWatch."""
    log_entry = {
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'level': 'INFO',
        'component': 'store-management-api',
        'operation': operation,
        'message': message
    }
    
    if store_id:
        log_entry['store_id'] = store_id
    
    if duration_ms is not None:
        log_entry['duration_ms'] = round(duration_ms, 2)
    
    print(json.dumps(log_entry))


def log_error(operation: str, store_id: Optional[str], error_message: str):
    """Log error message to CloudWatch."""
    log_entry = {
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'level': 'ERROR',
        'component': 'store-management-api',
        'operation': operation,
        'message': error_message
    }
    
    if store_id:
        log_entry['store_id'] = store_id
    
    print(json.dumps(log_entry))
