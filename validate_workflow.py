#!/usr/bin/env python3
"""
n8n Workflow JSON Validator
Validates the structure and format of n8n workflow JSON files
"""

import json
import sys
import os

def validate_workflow_json(file_path):
    """Validate n8n workflow JSON structure"""
    print(f"🔍 Validating workflow: {file_path}")
    
    try:
        with open(file_path, 'r') as f:
            workflow = json.load(f)
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON: {e}")
        return False
    except FileNotFoundError:
        print(f"❌ File not found: {file_path}")
        return False
    
    # Required top-level fields
    required_fields = ['name', 'nodes', 'connections']
    for field in required_fields:
        if field not in workflow:
            print(f"❌ Missing required field: {field}")
            return False
    
    # Validate nodes
    print("📋 Validating nodes...")
    node_ids = set()
    node_names = set()
    
    for i, node in enumerate(workflow['nodes']):
        # Check required node fields
        required_node_fields = ['id', 'name', 'type', 'typeVersion', 'position']
        for field in required_node_fields:
            if field not in node:
                print(f"❌ Node {i}: Missing required field '{field}'")
                return False
        
        # Check for duplicate IDs
        if node['id'] in node_ids:
            print(f"❌ Duplicate node ID: {node['id']}")
            return False
        node_ids.add(node['id'])
        
        # Check for duplicate names
        if node['name'] in node_names:
            print(f"❌ Duplicate node name: {node['name']}")
            return False
        node_names.add(node['name'])
        
        # Validate position is array with 2 numbers
        if not isinstance(node['position'], list) or len(node['position']) != 2:
            print(f"❌ Node {node['name']}: Invalid position format")
            return False
    
    # Validate connections
    print("🔗 Validating connections...")
    for source_node, connections in workflow['connections'].items():
        if source_node not in node_names:
            print(f"❌ Connection references unknown node: {source_node}")
            return False
        
        if 'main' not in connections:
            print(f"❌ Node {source_node}: Missing 'main' connection array")
            return False
        
        for connection_group in connections['main']:
            for connection in connection_group:
                if 'node' not in connection:
                    print(f"❌ Invalid connection format in {source_node}")
                    return False
                
                target_node = connection['node']
                if target_node not in node_names:
                    print(f"❌ Connection from {source_node} to unknown node: {target_node}")
                    return False
    
    # Check for orphaned nodes (nodes with no connections)
    connected_nodes = set()
    for connections in workflow['connections'].values():
        for connection_group in connections.get('main', []):
            for connection in connection_group:
                connected_nodes.add(connection['node'])
    
    # Find trigger nodes (should be connected but not have incoming connections)
    trigger_nodes = [node['name'] for node in workflow['nodes'] if 'cron' in node['type'].lower() or 'trigger' in node['type'].lower()]
    
    print("✅ Workflow validation passed!")
    print(f"📊 Summary:")
    print(f"   - Total nodes: {len(workflow['nodes'])}")
    print(f"   - Connected nodes: {len(connected_nodes)}")
    print(f"   - Trigger nodes: {len(trigger_nodes)}")
    
    return True

def main():
    """Main validation function"""
    workflow_file = "workflow.json"
    
    if not os.path.exists(workflow_file):
        print(f"❌ Workflow file not found: {workflow_file}")
        sys.exit(1)
    
    if validate_workflow_json(workflow_file):
        print("🎉 Workflow is valid and ready for import!")
        sys.exit(0)
    else:
        print("💥 Workflow validation failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
