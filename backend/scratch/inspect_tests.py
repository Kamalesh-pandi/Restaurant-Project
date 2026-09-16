import os
import glob
import xml.etree.ElementTree as ET

reports = glob.glob('target/surefire-reports/TEST-*.xml')
print(f'Total XML test reports: {len(reports)}')
total_tests = 0
total_failures = 0
total_errors = 0
total_skipped = 0

modules = {}
for r in reports:
    tree = ET.parse(r)
    root = tree.getroot()
    name = root.attrib.get('name')
    tests = int(root.attrib.get('tests', 0))
    failures = int(root.attrib.get('failures', 0))
    errors = int(root.attrib.get('errors', 0))
    skipped = int(root.attrib.get('skipped', 0))
    time = root.attrib.get('time', '0')
    total_tests += tests
    total_failures += failures
    total_errors += errors
    total_skipped += skipped
    
    parts = name.split('.')
    if len(parts) >= 4:
        mod = parts[3] if parts[3] != 'BackendApplicationTests' else 'core'
    else:
        mod = 'general'
    if mod not in modules:
        modules[mod] = []
    
    testcases = []
    for tc in root.findall('testcase'):
        tc_name = tc.attrib.get('name')
        tc_time = tc.attrib.get('time')
        tc_status = 'PASSED'
        if tc.find('failure') is not None:
            tc_status = 'FAILED'
        elif tc.find('error') is not None:
            tc_status = 'ERROR'
        elif tc.find('skipped') is not None:
            tc_status = 'SKIPPED'
        testcases.append({'name': tc_name, 'time': tc_time, 'status': tc_status})
        
    modules[mod].append({
        'class': name,
        'simple_name': parts[-1],
        'tests': tests,
        'failures': failures,
        'errors': errors,
        'skipped': skipped,
        'time': time,
        'testcases': testcases
    })

print(f'Total Tests: {total_tests}, Failures: {total_failures}, Errors: {total_errors}, Skipped: {total_skipped}')
for mod, clists in modules.items():
    print(f'Module: {mod} ({len(clists)} test suites)')
    for c in clists:
        print(f"  - {c['simple_name']}: {c['tests']} tests ({c['time']}s) - Failures: {c['failures']}, Errors: {c['errors']}")
        for tc in c['testcases']:
            print(f"      [{tc['status']}] {tc['name']} ({tc['time']}s)")
