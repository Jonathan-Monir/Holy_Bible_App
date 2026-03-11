# make_books_clean_footnotes_NT.py
# Place new_testament.docx next to this script and run it.
# Produces files in books_output/<EnglishName>.txt and <EnglishName>_footnotes.txt
import zipfile, xml.etree.ElementTree as ET, os, re

DOCX_PATH = "files/new_testament.docx"
OUTPUT_DIR = "new_books_output"

NS = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
DIACRITICS_RE = re.compile(r'[\u064B-\u065F\u0610-\u061A\u06D6-\u06ED]')

# New Testament Arabic to English mappings - using actual names from document
AR_TO_EN = {
    # Gospels
    "بُشْرَى (إنجيل) مَاتِثْيَاهُو": "Matthew",
    "بُشْرَى (إنجيل) مرقس": "Mark",
    "بُشْرَى (إنجيل) لوقا": "Luke",
    "بُشْرَى (إنجيل) يَهُوحَنَّان": "John",

    # Acts
    "سفر أعمال الروح القدس": "Acts",

    # Paul's Letters
    "رِسَالَةُ بُولُسَ إِلَى رُومَا": "Romans",
    "رِسَالَةُ بُولُسَ الأُولَى إِلَى كُورِنْثُوسَ": "1Corinthians",
    "رِسَالَةُ بُولُسَ الثَّانِيةُ إِلَى كُورِنْثُوسَ": "2Corinthians",
    "رِسَالَةُ بُولُسَ إِلَى غَلاَطِيَّةَ": "Galatians",
    "رِسَالَةُ بُولُسَ إِلَى أَفَسُسَ": "Ephesians",
    "رِسَالةُ بُولُسَ إِلَى فِيلِبِّي": "Philippians",   # note: no diacritic on رِسَالةُ
    "رِسَالَةُ بُولُسَ إِلَى كُولُوسِّي": "Colossians",
    "رِسَالَةُ بُولُسَ الأُولَى إِلَى تَسَالُونِيكِي": "1Thessalonians",
    "رِسَالَةُ بُولُسَ الثَّانِيةُ إِلَى تَسَالُونِيكِي": "2Thessalonians",
    "رِسَالَةُ بُولُسَ الأُولَى إِلَى تِيمُوثَاوُسَ": "1Timothy",
    "رِسَالَةُ بُولُسَ الثَّانِيةُ إِلَى تِيمُوثَاوُسَ": "2Timothy",
    "رِسَالَةُ بُولُسَ إِلَى تِيطُسَ": "Titus",
    "رِسَالَةُ بُولُسَ إِلَى فِلِيمُونَ": "Philemon",

    # General Epistles
    "اَلرِّسَالَةُ إِلَى الْعِبْرَانِيِّينَ": "Hebrews",
    "رِسَالَةُ يَعْقُوبَ": "James",
    "رِسَالَةُ بُطْرُسَ الأُولَى": "1Peter",
    "رِسَالَةُ بُطْرُسَ الثَّانِيَةُ": "2Peter",
    "رِسَالَةُ يَهُوحَنَّان الأُولَى": "1John",
    "رِسَالَةُ يَهُوحَنَّان الثَّانِيَةُ": "2John",
    "رِسَالَةُ يَهُوحَنَّان الثَّالِثَةُ": "3John",
    "رِسَالَةُ يَهُودَا": "Jude",

    # Revelation
    "رُؤْيَا يَهُوحَنَّان اللاَّهُوتِيِّ": "Revelation",
}

# Non-book titles to skip (preface, title pages, etc.)
SKIP_TITLES = {
    "الكِتَابُ المُقَدَّسُ: أَسْفَارُ العَهْدِ الجَدِيدِ",  # 48pt main title
    "تَرْجَمةٌ تَحْوِي اِسمَ يَهْوِه",
    "(تمت مراجعتها على الأصل اليوناني)",
    "الترجمة تمت بواسطة د. إڤرايم بشرى برسوم",
}

def strip_diacritics(s): 
    return DIACRITICS_RE.sub('', s or '')

def collect_text(elem):
    """Collect text from element preserving paragraph breaks inside it."""
    texts = []
    for child in elem:
        if child.tag == f"{{{NS['w']}}}p":  # nested paragraph
            texts.append(''.join(t.text or '' for t in child.findall('.//w:t', NS)).strip())
        else:
            # gather any w:t under this element
            for t in child.findall('.//w:t', NS):
                if t.text:
                    texts.append(t.text)
    # join with spaces, collapse repeated whitespace
    txt = ' '.join(t for t in texts if t)
    return re.sub(r'\s+', ' ', txt).strip()

def parse_document_xml(doc_xml_bytes):
    root = ET.fromstring(doc_xml_bytes)
    body = root.find('w:body', NS)
    paras = []
    if body is None:
        return paras
    
    # First pass: collect all footnote IDs in document order to establish global numbering
    global_footnote_map = {}
    footnote_counter = 0
    
    for p in body.findall('w:p', NS):
        for child in p:
            if child.tag == f'{{{NS["w"]}}}r':
                fn_ref = child.find('.//w:footnoteReference', NS)
                if fn_ref is not None:
                    fid = fn_ref.get(f'{{{NS["w"]}}}id')
                    if fid is not None and fid not in global_footnote_map:
                        footnote_counter += 1
                        global_footnote_map[fid] = footnote_counter
    
    # Second pass: build paragraphs with correct footnote numbers
    for p in body.findall('w:p', NS):
        text_parts = []
        refs = []
        
        for child in p:
            if child.tag == f'{{{NS["w"]}}}r':  # run
                # Check for footnote reference
                fn_ref = child.find('.//w:footnoteReference', NS)
                if fn_ref is not None:
                    fid = fn_ref.get(f'{{{NS["w"]}}}id')
                    if fid is not None:
                        refs.append(fid)
                        # Use the global footnote number
                        footnote_num = global_footnote_map.get(fid, '?')
                        text_parts.append(f'[{footnote_num}]')
                else:
                    # Regular text
                    for t in child.findall('.//w:t', NS):
                        if t.text:
                            text_parts.append(t.text)
        
        text = ''.join(text_parts).strip()
        paras.append({'text': text, 'refs': refs, 'elem': p})
    return paras

def read_footnotes_xml(footnotes_xml_bytes):
    """Return dict id -> (footnote-text, footnote-number). Only real footnotes kept."""
    if not footnotes_xml_bytes:
        return {}
    root = ET.fromstring(footnotes_xml_bytes)
    notes = {}
    
    for fn in root.findall('w:footnote', NS):
        fid = fn.get(f'{{{NS["w"]}}}id')
        typ = fn.get(f'{{{NS["w"]}}}type')
        if not fid or typ in ('separator', 'continuationSeparator'):
            continue
        
        parts = [ (''.join(t.text or '' for t in p.findall('.//w:t', NS))).strip() for p in fn.findall('.//w:p', NS) ]
        if parts:
            text = ' '.join(p for p in parts if p)
        else:
            text = ''.join(t.text or '' for t in fn.findall('.//w:t', NS)).strip()
        text = re.sub(r'\s+', ' ', text).strip()
        if text:
            notes[fid] = text
    return notes

def is_book_title_paragraph(p_elem, text_fallback=None):
    """Return True if paragraph element p_elem is formatted as a book title (28pt for NT)."""
    if p_elem is None:
        return False

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

    sizes = []
    # paragraph-level run properties
    ppr = p_elem.find('w:pPr', NS)
    if ppr is not None:
        sizes += sizes_from_rpr(ppr.find('w:rPr', NS))
    # runs
    for r in p_elem.findall('w:r', NS):
        sizes += sizes_from_rpr(r.find('w:rPr', NS))

    # Keep only numeric sizes
    sizes = [s for s in sizes if isinstance(s, int)]
    if sizes:
        # count how many runs use 28pt (56 half-points) - NT book titles
        count_28pt = sum(1 for s in sizes if s == 56)
        # treat as title if a majority are 28pt
        if count_28pt >= max(1, int(0.6 * len(sizes))):
            return True
        return False

    return False

import unicodedata

def normalize_arabic(text):
    t = text.replace('آ','ا').replace('أ','ا').replace('إ','ا')
    t = t.replace('ى','ي').replace('ء','').replace('ـ','')
    return re.sub(r'\s+', ' ', t).strip()

_HDR_RE = re.compile(r'^\s*(?:ال)?(?:اصحاح|اصح|فصل|chapter)\b', flags=re.I|re.U)

def is_chapter_header(text):
    if not text:
        return False
    s = strip_diacritics(text)
    s = normalize_arabic(s).lower()
    return bool(_HDR_RE.match(s))

def safe_filename(name):
    name = name.strip()
    name = re.sub(r'[\\/:"*?<>|]+', '', name)
    name = re.sub(r'\s+', '_', name)
    return name or 'book'

def arabic_to_english_filename(ar_name):
    key = ar_name.strip()
    
    # Try exact match first
    if key in AR_TO_EN: 
        return AR_TO_EN[key]
    
    # Try without diacritics
    stripped = strip_diacritics(key)
    for k, v in AR_TO_EN.items():
        if stripped == strip_diacritics(k):
            return v
    
    # Try normalized version
    normalized = normalize_arabic(key).lower()
    for k, v in AR_TO_EN.items():
        if normalized == normalize_arabic(k).lower():
            return v
    
    # Try prefix matching
    for k, v in AR_TO_EN.items():
        if stripped.startswith(strip_diacritics(k)) or key.startswith(k):
            return v
    
    # If not found, print warning
    print(f"⚠️  BOOK NAME NOT FOUND IN MAPPING: '{key}'")
    print(f"   Stripped (no diacritics): '{stripped}'")
    print(f"   Normalized: '{normalized}'")
    print(f"   Please add this to AR_TO_EN dictionary")
    print()
    
    # Fallback to transliterated or sanitized name
    ascii = re.sub(r'[^\x00-\x7F]+', '', key).strip()
    if ascii:
        return safe_filename(ascii)
    else:
        return safe_filename(f"UnknownBook_{key[:20]}")

def write_files(book_ar, chapters):
    eng = arabic_to_english_filename(book_ar)
    base = safe_filename(eng)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    book_path = os.path.join(OUTPUT_DIR, f"{base}.txt")
    foot_path = os.path.join(OUTPUT_DIR, f"{base}_footnotes.txt")
    
    # Write book text (only verses/paragraphs)
    with open(book_path, 'w', encoding='utf-8') as bf:
        for chap_title, chap in chapters.items():
            bf.write(chap_title + '\n')
            for para in chap['paras']:
                bf.write(para + '\n\n')
    
    # Write footnotes with their actual numbers from the document
    with open(foot_path, 'w', encoding='utf-8') as ff:
        for chap_title, chap in chapters.items():
            if not chap.get('footnotes_with_numbers'):
                continue
            ff.write(chap_title + '\n')
            # Write footnotes with their original numbers
            for fn_num, fn_text in chap['footnotes_with_numbers']:
                ff.write(f'[{fn_num}] {fn_text}\n\n')
    
    print(f"✓ {base}.txt and {base}_footnotes.txt")

def process_docx(path):
    with zipfile.ZipFile(path) as z:
        try:
            doc_xml = z.read('word/document.xml')
        except KeyError:
            raise FileNotFoundError("word/document.xml not present in docx")
        footnotes_xml = None
        try:
            footnotes_xml = z.read('word/footnotes.xml')
        except KeyError:
            footnotes_xml = None

    paras = parse_document_xml(doc_xml)
    footnotes_map = read_footnotes_xml(footnotes_xml)

    current_book = None
    chapters = {}
    current_chapter = None
    all_texts = {}

    for p in paras:
        text = p['text']
        refs = p['refs']

        if is_book_title_paragraph(p['elem'], text):
            if not text.strip():
                continue
            # Skip non-book titles (preface, title pages, etc.)
            if text.strip() in SKIP_TITLES:
                print(f"⏭️  Skipping non-book content: {text[:60]}...")
                continue
            
            # Check if this is a known book
            if text.strip() not in AR_TO_EN:
                # Try without diacritics
                stripped = strip_diacritics(text.strip())
                found = False
                for k in AR_TO_EN.keys():
                    if stripped == strip_diacritics(k):
                        found = True
                        break
                if not found:
                    print(f"⏭️  Skipping unknown title: {text[:60]}...")
                    continue
            
            # Save previous book
            if current_book:
                total_len = sum(len('\n'.join(chap['paras'])) for chap in chapters.values())
                all_texts[current_book] = total_len
                write_files(current_book, chapters)
            
            # Start new book
            current_book = text
            chapters = {}
            current_chapter = None
            continue

        if is_chapter_header(text):
            current_chapter = text or 'المجهول'
            if current_chapter not in chapters:
                chapters[current_chapter] = {
                    'paras': [], 
                    'footnotes_set': set(), 
                    'footnotes_ordered': [], 
                    'footnotes_with_numbers': [],
                    'footnote_counter': 0
                }
            continue

        if not current_book:
            continue

        if not current_chapter:
            current_chapter = 'مقدمة'
            if current_chapter not in chapters:
                chapters[current_chapter] = {
                    'paras': [], 
                    'footnotes_set': set(), 
                    'footnotes_ordered': [],
                    'footnotes_with_numbers': []
                }

        # Keep original footnote numbers with their actual document numbers
        if refs:
            # Get the actual footnote numbers from the text that was just built
            footnote_nums_in_text = []
            for match in re.finditer(r'\[(\d+)\]', text):
                footnote_nums_in_text.append(int(match.group(1)))
            
            # Collect footnotes with their actual numbers
            for i, fid in enumerate(refs):
                fn_text = footnotes_map.get(fid)
                if fn_text and i < len(footnote_nums_in_text):
                    fn_num = footnote_nums_in_text[i]
                    footnote_key = (fid, fn_text)
                    if footnote_key not in chapters[current_chapter]['footnotes_set']:
                        chapters[current_chapter]['footnotes_set'].add(footnote_key)
                        if 'footnotes_with_numbers' not in chapters[current_chapter]:
                            chapters[current_chapter]['footnotes_with_numbers'] = []
                        chapters[current_chapter]['footnotes_with_numbers'].append((fn_num, fn_text))
        
        # Append paragraph text to the book file
        if text:
            chapters[current_chapter]['paras'].append(text)

    # Flush last book
    if current_book:
        total_len = sum(len('\n'.join(chap['paras'])) for chap in chapters.values())
        all_texts[current_book] = total_len
        write_files(current_book, chapters)
    else:
        print("No book title detected. Adjust heuristics.")

    print("\n" + "="*50)
    print("SUMMARY - Books processed:")
    print("="*50)
    for book, size in sorted(all_texts.items(), key=lambda x: x[1], reverse=True):
        eng_name = arabic_to_english_filename(book)
        print(f"{eng_name:25} {size:6} chars")
    print("="*50)
    print(f"Total books: {len(all_texts)}")
    
    # Count actual NT books (exclude introductions and unknown)
    actual_books = [b for b in all_texts.keys() if b in AR_TO_EN.values() or AR_TO_EN.get(b)]
    nt_books = [ar for ar in all_texts.keys() if ar in AR_TO_EN]
    print(f"NT books found: {len(nt_books)}")

if __name__ == "__main__":
    if not os.path.exists(DOCX_PATH):
        print(f"ERROR: {DOCX_PATH} not found!")
        print(f"Please place {DOCX_PATH} in the same directory as this script.")
    else:
        print(f"Processing {DOCX_PATH}...\n")
        process_docx(DOCX_PATH)
