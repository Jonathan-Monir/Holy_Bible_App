# make_books_clean_footnotes_NT.py
# Place new_testament.docx next to this script and run it.
# Produces files in books_output/<EnglishName>.txt and <EnglishName>_footnotes.txt
import zipfile, xml.etree.ElementTree as ET, os, re

DOCX_PATH = "files/new_testament.docx"
OUTPUT_DIR = "new_books_output"

NS = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
DIACRITICS_RE = re.compile(r'[\u064B-\u065F\u0610-\u061A\u06D6-\u06ED]')

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
    "رِسَالةُ بُولُسَ إِلَى فِيلِبِّي": "Philippians",
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

SKIP_TITLES = {
    "الكِتَابُ المُقَدَّسُ: أَسْفَارُ العَهْدِ الجَدِيدِ",
    "تَرْجَمةٌ تَحْوِي اِسمَ يَهْوِه",
    "(تمت مراجعتها على الأصل اليوناني)",
    "الترجمة تمت بواسطة د. إڤرايم بشرى برسوم",
}

def strip_diacritics(s):
    return DIACRITICS_RE.sub('', s or '')

def parse_document_xml(doc_xml_bytes):
    root = ET.fromstring(doc_xml_bytes)
    body = root.find('w:body', NS)
    paras = []
    if body is None:
        return paras

    # First pass: global footnote numbering
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

    # Second pass: build paragraphs
    for p in body.findall('w:p', NS):
        text_parts = []
        refs = []
        for child in p:
            if child.tag == f'{{{NS["w"]}}}r':
                fn_ref = child.find('.//w:footnoteReference', NS)
                if fn_ref is not None:
                    fid = fn_ref.get(f'{{{NS["w"]}}}id')
                    if fid is not None:
                        refs.append(fid)
                        footnote_num = global_footnote_map.get(fid, '?')
                        text_parts.append(f'[{footnote_num}]')
                else:
                    for t in child.findall('.//w:t', NS):
                        if t.text:
                            text_parts.append(t.text)
        text = ''.join(text_parts).strip()
        paras.append({'text': text, 'refs': refs, 'elem': p})
    return paras

def read_footnotes_xml(footnotes_xml_bytes):
    if not footnotes_xml_bytes:
        return {}
    root = ET.fromstring(footnotes_xml_bytes)
    notes = {}
    for fn in root.findall('w:footnote', NS):
        fid = fn.get(f'{{{NS["w"]}}}id')
        typ = fn.get(f'{{{NS["w"]}}}type')
        if not fid or typ in ('separator', 'continuationSeparator'):
            continue
        parts = [(''.join(t.text or '' for t in p.findall('.//w:t', NS))).strip() for p in fn.findall('.//w:p', NS)]
        text = ' '.join(p for p in parts if p) if parts else ''.join(t.text or '' for t in fn.findall('.//w:t', NS)).strip()
        text = re.sub(r'\s+', ' ', text).strip()
        if text:
            notes[fid] = text
    return notes

def is_book_title_paragraph(p_elem):
    if p_elem is None:
        return False

    def sizes_from_rpr(rpr):
        vals = []
        if rpr is None:
            return vals
        for tag in ('sz', 'szCs'):
            el = rpr.find(f"w:{tag}", NS)
            if el is not None:
                v = el.get(f"{{{NS['w']}}}val")
                if v and v.isdigit():
                    vals.append(int(v))
        return vals

    sizes = []
    ppr = p_elem.find('w:pPr', NS)
    if ppr is not None:
        sizes += sizes_from_rpr(ppr.find('w:rPr', NS))
    for r in p_elem.findall('w:r', NS):
        sizes += sizes_from_rpr(r.find('w:rPr', NS))

    sizes = [s for s in sizes if isinstance(s, int)]
    if sizes:
        count_28pt = sum(1 for s in sizes if s == 56)
        return count_28pt >= max(1, int(0.6 * len(sizes)))
    return False

def normalize_arabic(text):
    t = text.replace('آ', 'ا').replace('أ', 'ا').replace('إ', 'ا')
    t = t.replace('ى', 'ي').replace('ء', '').replace('ـ', '')
    return re.sub(r'\s+', ' ', t).strip()

_HDR_RE = re.compile(r'^\s*(?:ال)?(?:اصحاح|اصح|فصل|chapter)\b', flags=re.I | re.U)

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
    if key in AR_TO_EN:
        return AR_TO_EN[key]
    stripped = strip_diacritics(key)
    for k, v in AR_TO_EN.items():
        if stripped == strip_diacritics(k):
            return v
    normalized = normalize_arabic(key).lower()
    for k, v in AR_TO_EN.items():
        if normalized == normalize_arabic(k).lower():
            return v
    ascii_name = re.sub(r'[^\x00-\x7F]+', '', key).strip()
    return safe_filename(ascii_name) if ascii_name else safe_filename(f"UnknownBook_{key[:20]}")

def write_files(book_ar, chapters):
    eng = arabic_to_english_filename(book_ar)
    base = safe_filename(eng)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    book_path = os.path.join(OUTPUT_DIR, f"{base}.txt")
    foot_path = os.path.join(OUTPUT_DIR, f"{base}_footnotes.txt")

    with open(book_path, 'w', encoding='utf-8') as bf:
        for chap_title, chap in chapters.items():
            bf.write(chap_title + '\n')
            for para in chap['paras']:
                bf.write(para + '\n\n')

    with open(foot_path, 'w', encoding='utf-8') as ff:
        for chap_title, chap in chapters.items():
            if not chap.get('footnotes_with_numbers'):
                continue
            ff.write(chap_title + '\n')
            for fn_num, fn_text in chap['footnotes_with_numbers']:
                ff.write(f'[{fn_num}] {fn_text}\n\n')

    print(f"✓ {base}.txt and {base}_footnotes.txt")

def process_docx(path):
    with zipfile.ZipFile(path) as z:
        try:
            doc_xml = z.read('word/document.xml')
        except KeyError:
            raise FileNotFoundError("word/document.xml not present in docx")
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

        if is_book_title_paragraph(p['elem']):
            # Skip empty paragraphs that happen to be 28pt
            if not text.strip():
                continue

            # Skip known non-book content
            if text.strip() in SKIP_TITLES:
                print(f"⏭️  Skipping non-book content: {text[:60]}...")
                continue

            # Check if this is a known book (exact or diacritic-stripped match)
            stripped = strip_diacritics(text.strip())
            found = text.strip() in AR_TO_EN or any(
                stripped == strip_diacritics(k) for k in AR_TO_EN
            )
            if not found:
                print(f"⏭️  Skipping unknown title: {text[:60]}...")
                continue

            # Save previous book
            if current_book:
                total_len = sum(len('\n'.join(chap['paras'])) for chap in chapters.values())
                all_texts[current_book] = total_len
                write_files(current_book, chapters)

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
                    'footnotes_with_numbers': [],
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
                    'footnotes_with_numbers': [],
                }

        if refs:
            footnote_nums_in_text = [int(m.group(1)) for m in re.finditer(r'\[(\d+)\]', text)]
            for i, fid in enumerate(refs):
                fn_text = footnotes_map.get(fid)
                if fn_text and i < len(footnote_nums_in_text):
                    fn_num = footnote_nums_in_text[i]
                    footnote_key = (fid, fn_text)
                    if footnote_key not in chapters[current_chapter]['footnotes_set']:
                        chapters[current_chapter]['footnotes_set'].add(footnote_key)
                        chapters[current_chapter]['footnotes_with_numbers'].append((fn_num, fn_text))

        if text:
            chapters[current_chapter]['paras'].append(text)

    # Flush last book
    if current_book:
        total_len = sum(len('\n'.join(chap['paras'])) for chap in chapters.values())
        all_texts[current_book] = total_len
        write_files(current_book, chapters)
    else:
        print("No book title detected. Adjust heuristics.")

    print("\n" + "=" * 50)
    print("SUMMARY - Books processed:")
    print("=" * 50)
    for book, size in sorted(all_texts.items(), key=lambda x: x[1], reverse=True):
        eng_name = arabic_to_english_filename(book)
        print(f"{eng_name:25} {size:6} chars")
    print("=" * 50)
    print(f"Total books: {len(all_texts)}")
    nt_books = [ar for ar in all_texts.keys() if ar in AR_TO_EN]
    print(f"NT books found: {len(nt_books)}")

if __name__ == "__main__":
    if not os.path.exists(DOCX_PATH):
        print(f"ERROR: {DOCX_PATH} not found!")
    else:
        print(f"Processing {DOCX_PATH}...\n")
        process_docx(DOCX_PATH)
