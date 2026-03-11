# diagnose_new_testament.py
# This script will help us understand the structure of new_testament.docx
import zipfile, xml.etree.ElementTree as ET, re

DOCX_PATH = "files/new_testament.docx"
NS = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}

def get_font_sizes(p_elem):
    """Extract all font sizes from a paragraph."""
    sizes = []
    
    def sizes_from_rpr(rpr):
        vals = []
        if rpr is None:
            return vals
        for tag in ('sz','szCs'):
            el = rpr.find(f"w:{tag}", NS)
            if el is not None:
                v = el.get(f"{{{NS['w']}}}val")
                if v and v.isdigit():
                    vals.append(int(v))
        return vals
    
    # paragraph-level run properties
    ppr = p_elem.find('w:pPr', NS)
    if ppr is not None:
        sizes += sizes_from_rpr(ppr.find('w:rPr', NS))
    
    # runs
    for r in p_elem.findall('w:r', NS):
        sizes += sizes_from_rpr(r.find('w:rPr', NS))
    
    return sizes

def get_paragraph_text(p_elem):
    """Get text from paragraph."""
    text_parts = []
    for r in p_elem.findall('w:r', NS):
        for t in r.findall('.//w:t', NS):
            if t.text:
                text_parts.append(t.text)
    return ''.join(text_parts).strip()

def is_arabic(text):
    """Check if text contains Arabic characters."""
    return bool(re.search(r'[\u0600-\u06FF]', text))

def diagnose_docx(path):
    with zipfile.ZipFile(path) as z:
        try:
            doc_xml = z.read('word/document.xml')
        except KeyError:
            print("ERROR: word/document.xml not found!")
            return
    
    root = ET.fromstring(doc_xml)
    body = root.find('w:body', NS)
    
    if body is None:
        print("ERROR: No body found in document!")
        return
    
    paras = body.findall('w:p', NS)
    print(f"Total paragraphs: {len(paras)}\n")
    print("="*80)
    print("FIRST 50 PARAGRAPHS (with font sizes):")
    print("="*80)
    
    for i, p in enumerate(paras[:50]):
        text = get_paragraph_text(p)
        if not text:
            continue
            
        sizes = get_font_sizes(p)
        unique_sizes = list(set(sizes)) if sizes else []
        
        # Show first 100 chars of text
        display_text = text[:100] + "..." if len(text) > 100 else text
        
        print(f"\n[Para {i+1}]")
        print(f"Text: {display_text}")
        print(f"Sizes: {unique_sizes} (count: {len(sizes)})")
        print(f"Is Arabic: {is_arabic(text)}")
        
        # Check for patterns
        if sizes and any(s >= 48 for s in sizes):  # 24pt or larger
            print(f">>> LARGE TEXT DETECTED (might be title)")
    
    print("\n" + "="*80)
    print("FONT SIZE DISTRIBUTION:")
    print("="*80)
    
    all_sizes = []
    for p in paras:
        all_sizes.extend(get_font_sizes(p))
    
    if all_sizes:
        size_counts = {}
        for s in all_sizes:
            size_counts[s] = size_counts.get(s, 0) + 1
        
        for size, count in sorted(size_counts.items(), reverse=True):
            print(f"{size//2}pt ({size} half-pts): {count} occurrences")
    else:
        print("No font sizes found!")
    
    print("\n" + "="*80)
    print("LOOKING FOR POSSIBLE BOOK TITLES:")
    print("="*80)
    
    # Look for paragraphs with Arabic text and larger fonts
    candidates = []
    for i, p in enumerate(paras):
        text = get_paragraph_text(p)
        if not text or not is_arabic(text):
            continue
        
        sizes = get_font_sizes(p)
        if sizes:
            max_size = max(sizes)
            if max_size >= 48:  # 24pt or larger
                candidates.append((i+1, text[:80], max_size))
    
    if candidates:
        for para_num, text, size in candidates:
            print(f"\n[Para {para_num}] Size: {size//2}pt")
            print(f"Text: {text}")
    else:
        print("No obvious title candidates found!")
        print("\nTrying to find ANY Arabic paragraphs with distinct formatting:")
        
        for i, p in enumerate(paras[:100]):
            text = get_paragraph_text(p)
            if text and is_arabic(text):
                sizes = get_font_sizes(p)
                if sizes and len(text) < 100:  # Short text might be a title
                    print(f"\n[Para {i+1}] Sizes: {list(set(sizes))}")
                    print(f"Text: {text}")

if __name__ == "__main__":
    import os
    # if not os.path.exists(DOCX_PATH):
    #     print(f"ERROR: {DOCX_PATH} not found!")
    # else:
    diagnose_docx(DOCX_PATH)
