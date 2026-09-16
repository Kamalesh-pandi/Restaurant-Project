import fitz

doc = fitz.open(r'C:\Restaurant Project\Restaurant_Management_and_POS_System_Project_Report.pdf')
print("Total pages:", len(doc))
for pno in range(len(doc)):
    page = doc[pno]
    txt = page.get_text().strip().replace('\n', ' ')
    imgs = page.get_images()
    print(f"P{pno+1:02d}: Imgs={len(imgs)}, Chars={len(txt)}, First70=\"{txt[:70]}\"")
