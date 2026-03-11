# make_books_clean_footnotes.py
# Place old_testament.docx next to this script and run it.
# Produces files in books_output/<EnglishName>.txt and <EnglishName>_footnotes.txt
import zipfile, xml.etree.ElementTree as ET, os, re

DOCX_PATH = "files/old_testament.docx"
OUTPUT_DIR = "books_output"

NS = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
DIACRITICS_RE = re.compile(r'[\u064B-\u065F\u0610-\u061A\u06D6-\u06ED]')

AR_TO_EN = {
    "التكوين": "Genesis", "الخروج": "Exodus", "اللاويين": "Leviticus",
    "العدد": "Numbers", "التثنية": "Deuteronomy", "يهوشع": "Joshua",
    "المدبرون": "Judges", "رُوث (راعوث)": "Ruth",     "صموئيل الأول": "1Samuel",
    "صموئيل الثاني": "2Samuel", "ملوك الأول": "1Kings",
    "ملوك الثاني": "2Kings", "كلام الأيام الأول": "1Chronicles",
    "كلام الأيام الثاني": "2Chronicles", "عزرا": "Ezra",
    "نحميا": "Nehemiah", "استير": "Esther", "أيوب": "Job",
    "المزامير": "Psalms", "الأمثال": "Proverbs", "كُوِهِلِتْ (مَجْمَعُ קֹהֶלֶת)": "Ecclesiastes",
    "\"أُغْنِيَةُ الأَغَانِي\"": "Song_of_Songs", "يَشَعْيَاهُو": "Isaiah", "يَرْمِيَاهُو": "Jeremiah",
    "مَرَاثِي يَرْمِيَاهُو": "Lamentations", "يَحَزْقَئِيلُ": "Ezekiel", "دانيال": "Daniel",
    "هوشع": "Hosea", "يوئيل": "Joel", "عاموس": "Amos", "عوبديا": "Obadiah",
    "يونان": "Jonah", "ميخا": "Micah", "ناحو": "Nahum", "حبقوق": "Habakkuk",
    "صَفَنْيَاه": "Zephaniah", "حَجَّي": "Haggai", "زكريا": "Zechariah",
    "مَلاَخِي (مَبْعُوثِي מַלְאָכִֽי)": "Malachi"
}

def strip_diacritics(s): return DIACRITICS_RE.sub('', s or '')

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
    footnote_counter = {}  # Track footnote numbers per chapter
    
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
    """Return True if paragraph element p_elem is formatted as a book title (36pt)."""
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
        # count how many runs use 36pt (72 half-points)
        count_36pt = sum(1 for s in sizes if s == 72)
        # treat as title if a majority (or at least one strong marker) are 36pt
        if count_36pt >= max(1, int(0.6 * len(sizes))):
            return True
        return False

    # fallback to text heuristics if no sizing info found
    if not text_fallback:
        return False
    t = re.sub(r'^[\d\u0660-\u0669]+\s*[-–\.]?\s*', '', text_fallback.strip())
    return bool(re.match(r'^[\u0600-\u06FF]', t))

import re
import unicodedata

def strip_diacritics(text):
    return ''.join(
        c for c in unicodedata.normalize('NFD', text)
        if unicodedata.category(c) != 'Mn'
    )

def normalize_arabic(text):
    t = text.replace('آ','ا').replace('أ','ا').replace('إ','ا')
    t = t.replace('ى','ي').replace('ء','').replace('ـ','')  # optional tweaks
    return re.sub(r'\s+', ' ', t).strip()

# More strict chapter header pattern that requires ordinal numbers (like "الثالث", "الأول", etc.)
# This pattern specifically looks for "ال" + ordinal number words after the chapter keyword
_HDR_RE = re.compile(
    r'^\s*(?:ال)?(?:اصحاح|اصح|فصل|مزمور)\s+(?:ال)?(?:اول|ثان|ثالث|رابع|خامس|سادس|سابع|ثامن|تاسع|عاشر|حاد|مية|مئة|ستون|سبعون|ثمانون|تسعون|خمسون|اربعون|ثلاثون|عشرون|عشر)',
    flags=re.I|re.U
)

def is_chapter_header(text):
    """
    Detect chapter headers like:
    - اَلْمَزْمُورُ الثَّالِثُ وَالْعِشْرُونَ (Psalm 23)
    - الاصحاح الأول (Chapter 1)
    
    But NOT subtitles like:
    - مَزْمُورٌ لِدَاوُدَ (A Psalm of David)
    - لِدَاوُدَ (For David)
    """
    if not text:
        return False
    s = strip_diacritics(text)
    s = normalize_arabic(s).lower()
    
    # Must match the pattern with a number/ordinal after the keyword
    result = bool(_HDR_RE.match(s))
    
    # DEBUG: Print what we're checking
    if 'مزمور' in text or 'المزمور' in text:
        print(f"DEBUG is_chapter_header: '{text[:50]}...' -> normalized: '{s[:50]}...' -> {result}")
    
    return result


def safe_filename(name):
    name = name.strip()
    name = re.sub(r'[\\/:"*?<>|]+', '', name)
    name = re.sub(r'\s+', '_', name)
    return name or 'book'

def arabic_to_english_filename(ar_name):
    key = ar_name.strip()
    if key in AR_TO_EN: return AR_TO_EN[key]
    stripped = strip_diacritics(key)
    for k, v in AR_TO_EN.items():
        if stripped.startswith(strip_diacritics(k)) or key.startswith(k):
            return v
    ascii = re.sub(r'[^\x00-\x7F]+', '', key).strip() or 'Book'
    return safe_filename(ascii)

def write_files(book_ar, chapters):
    eng = arabic_to_english_filename(book_ar)
    base = safe_filename(eng)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    book_path = os.path.join(OUTPUT_DIR, f"{base}.txt")
    foot_path = os.path.join(OUTPUT_DIR, f"{base}_footnotes.txt")
    
    # DEBUG: Print what we're writing
    print(f"\nDEBUG write_files: Writing {base}.txt with {len(chapters)} chapters")
    for ch_title in list(chapters.keys())[:3]:  # Show first 3 chapters
        print(f"  Chapter: {ch_title[:50]}... ({len(chapters[ch_title]['paras'])} paragraphs)")
    
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
    print(f"{foot_path}")

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
    for i, p in enumerate(paras):
        text = p['text']
        refs = p['refs']

        if is_book_title_paragraph(p['elem'], text):


            if current_book:
                total_len = sum(len('\n'.join(chap['paras'])) for chap in chapters.values())
                all_texts[current_book] = len(text)


            if is_book_title_paragraph(p['elem'], text):
                if current_book:
                    print(current_book)
            if current_book:
                write_files(current_book, chapters)
            current_book = text
            chapters = {}
            current_chapter = None
            print(f"\nDEBUG: NEW BOOK detected: {text[:50]}...")
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
            print(f"DEBUG: NEW CHAPTER detected: {text[:50]}...")
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
        
        # Append paragraph text always to the book file (verses).
        if text:
            chapters[current_chapter]['paras'].append(text)

    # flush last book
    if current_book:
        total_len = sum(len('\n'.join(chap['paras'])) for chap in chapters.values())
        all_texts[current_book] = total_len
        write_files(current_book, chapters)
    else:
        print("No book title detected. Adjust heuristics.")

    for book, size in sorted(all_texts.items(), key=lambda x: x[1], reverse=True):
        print(book, size)
    print(len(all_texts))

if __name__ == "__main__":
    process_docx(DOCX_PATH)
