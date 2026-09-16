import os
import shutil

with open('scratch/build_full_report.py', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace curly quotes and dashes that don't map to standard Times-Roman ASCII
code = code.replace('\u201c', '"').replace('\u201d', '"').replace('\u2018', "'").replace('\u2019', "'")
code = code.replace('\u2013', '-').replace('\u2014', '-').replace('\u2713', '-')
code = code.replace('"REFERENCES", style_body), "35"', '"REFERENCES", style_body), "34"')

with open('scratch/build_full_report.py', 'w', encoding='utf-8') as f:
    f.write(code)

print("Updated scratch/build_full_report.py successfully")
