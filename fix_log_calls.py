#!/usr/bin/env python3
"""
快速修复LogHelper调用的脚本
将单参数调用改为双参数调用
"""

import os
import re

def fix_log_calls(file_path):
    """修复文件中的LogHelper调用"""
    if not os.path.exists(file_path):
        return False
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # 修复LogHelper.info单参数调用
        content = re.sub(
            r"LogHelper\.info\('([^']+)'\);",
            r"LogHelper.info('\1', 'Operation completed');",
            content
        )
        
        # 修复LogHelper.warn单参数调用
        content = re.sub(
            r"LogHelper\.warn\('([^']+)'\);",
            r"LogHelper.warn('\1', 'Warning occurred');",
            content
        )
        
        # 修复LogHelper.error单参数调用
        content = re.sub(
            r"LogHelper\.error\('([^']+)'\);",
            r"LogHelper.error('\1', 'Error occurred');",
            content
        )
        
        # 修复LogHelper.debug单参数调用
        content = re.sub(
            r"LogHelper\.debug\('([^']+)'\);",
            r"LogHelper.debug('\1', 'Debug info');",
            content
        )
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed: {file_path}")
            return True
        else:
            print(f"No changes needed: {file_path}")
            return False
            
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    """主函数"""
    base_path = "d:/DevEco_product/Weatherforecast/entry/src/main/ets"
    
    # 需要修复的文件列表
    files_to_fix = [
        "common/utils/ResourceManager.ets",
        "common/utils/ResourceHealthChecker.ets", 
        "common/utils/CityManagementTester.ets",
        "components/debug/ResourceStatusOverlay.ets",
        "components/debug/DatabaseInspector.ets"
    ]
    
    fixed_count = 0
    for file_path in files_to_fix:
        full_path = os.path.join(base_path, file_path)
        if fix_log_calls(full_path):
            fixed_count += 1
    
    print(f"\nFixed {fixed_count} files")

if __name__ == "__main__":
    main()
