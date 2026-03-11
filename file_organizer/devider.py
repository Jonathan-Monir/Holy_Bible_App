# extract_books_fixed.py
import PyPDF2
import re
import os

# Mapping of Arabic book names to English file names
BOOK_MAPPING = {
    "التكوين": "Genesis",
    "الخروج": "Exodus", 
    "اللاويين": "Leviticus",
    "العدد": "Numbers",
    "التثنية": "Deuteronomy",
    "يشوع": "Joshua",
    "القضاة": "Judges",
    "راعوث": "Ruth",
    "صموئيل الأول": "1_Samuel",
    "صموئيل الثاني": "2_Samuel",
    "الملوك الأول": "1_Kings",
    "الملوك الثاني": "2_Kings",
    "أخبار الأيام الأول": "1_Chronicles",
    "أخبار الأيام الثاني": "2_Chronicles",
    "عزرا": "Ezra",
    "نحميا": "Nehemiah",
    "أستير": "Esther",
    "أيوب": "Job",
    "المزامير": "Psalms",
    "الأمثال": "Proverbs",
    "الجامعة": "Ecclesiastes",
    "نشيد الأنشاد": "Song_of_Solomon",
    "إشعياء": "Isaiah",
    "إرميا": "Jeremiah",
    "مراثي إرميا": "Lamentations",
    "حزقيال": "Ezekiel",
    "دانيال": "Daniel",
    "هوشع": "Hosea",
    "يوئيل": "Joel",
    "عاموس": "Amos",
    "عوبديا": "Obadiah",
    "يونان": "Jonah",
    "ميخا": "Micah",
    "ناحوم": "Nahum",
    "حبقوق": "Habakkuk",
    "صفنيا": "Zephaniah",
    "حجي": "Haggai",
    "زكريا": "Zechariah",
    "ملاخي": "Malachi"
}

def extract_text_from_pdf(pdf_path):
    """Extract all text from PDF file"""
    print(f"Reading PDF: {pdf_path}")
    
    with open(pdf_path, 'rb') as file:
        pdf_reader = PyPDF2.PdfReader(file)
        text = ""
        
        for page_num in range(len(pdf_reader.pages)):
            page = pdf_reader.pages[page_num]
            text += page.extract_text() + "\n"
            
            # Show progress
            if (page_num + 1) % 50 == 0:
                print(f"Processed {page_num + 1} pages...")
    
    print(f"Extracted {len(text)} characters from PDF")
    return text

def fix_arabic_spacing(text):
    """Fix the spacing issues in Arabic text from PDF extraction"""
    # Remove spaces between Arabic letters but keep spaces between words
    # This is a simplified approach - we'll remove spaces between Arabic characters
    lines = text.split('\n')
    fixed_lines = []
    
    for line in lines:
        # Skip lines that are mostly numbers or footnotes
        if re.match(r'^\d+\s*\)', line) or re.match(r'^\s*\d+\s*$', line):
            fixed_lines.append(line)
            continue
            
        # For Arabic text lines, try to fix the spacing
        words = line.split()
        fixed_words = []
        
        for word in words:
            # If word contains Arabic characters, don't split it further
            if re.search(r'[ا-ي]', word):
                # Remove internal spaces in Arabic words
                cleaned_word = re.sub(r'\s+', '', word)
                fixed_words.append(cleaned_word)
            else:
                fixed_words.append(word)
        
        fixed_line = ' '.join(fixed_words)
        fixed_lines.append(fixed_line)
    
    return '\n'.join(fixed_lines)

def find_book_titles_in_text(text):
    """Find book titles in the text using pattern matching"""
    print("Searching for book titles...")
    
    # Pattern for book titles like "1 - التكوي ن"
    book_pattern = r'(\d+\s*-\s*[ا-ي\s]+)'
    matches = re.findall(book_pattern, text)
    
    book_titles = []
    for match in matches:
        # Clean up the title
        title = re.sub(r'\d+\s*-\s*', '', match).strip()
        # Remove extra spaces between Arabic letters
        title = re.sub(r'\s+', '', title)
        book_titles.append(title)
    
    print(f"Found {len(book_titles)} potential book titles: {book_titles[:10]}")
    return book_titles

def extract_books_manual(text):
    """Manually extract books based on the observed PDF structure"""
    print("Extracting books using manual pattern matching...")
    
    # Split text into lines
    lines = text.split('\n')
    
    books = {}
    current_book = None
    current_content = []
    current_footnotes = []
    collecting_footnotes = False
    
    # Pattern to identify book titles
    book_title_pattern = r'^\s*(\d+\s*-\s*[ا-ي\s]+)\s*$'
    
    for i, line in enumerate(lines):
        line = line.strip()
        if not line:
            continue
        
        # Check for book title
        book_match = re.match(book_title_pattern, line)
        if book_match:
            # Save previous book
            if current_book and current_content:
                main_text = '\n'.join(current_content)
                footnote_text = '\n'.join(current_footnotes)
                
                # Clean the book title
                clean_title = re.sub(r'\d+\s*-\s*', '', current_book).strip()
                clean_title = re.sub(r'\s+', '', clean_title)
                
                books[clean_title] = {
                    'main_text': main_text,
                    'footnotes': footnote_text
                }
                print(f"  Extracted: {clean_title}")
            
            # Start new book
            current_book = line
            current_content = [line]
            current_footnotes = []
            collecting_footnotes = False
            continue
        
        if current_book:
            # Check if this line starts a footnote section
            if (re.match(r'^\d+\s*\)', line) or 
                ('يفسر' in line and len(line) > 50) or
                ('يشرح' in line and len(line) > 50)):
                collecting_footnotes = True
            
            if collecting_footnotes:
                current_footnotes.append(line)
            else:
                current_content.append(line)
    
    # Save last book
    if current_book and current_content:
        main_text = '\n'.join(current_content)
        footnote_text = '\n'.join(current_footnotes)
        
        clean_title = re.sub(r'\d+\s*-\s*', '', current_book).strip()
        clean_title = re.sub(r'\s+', '', clean_title)
        
        books[clean_title] = {
            'main_text': main_text,
            'footnotes': footnote_text
        }
        print(f"  Extracted: {clean_title}")
    
    return books

def improved_book_extraction(text):
    """Improved extraction that handles the specific PDF format and preserves footnote numbers"""
    print("Using improved extraction for PDF format...")
    
    # First, fix the Arabic spacing issues
    fixed_text = fix_arabic_spacing(text)
    
    # Split into lines
    lines = fixed_text.split('\n')
    
    books = {}
    current_book = None
    current_content = []
    current_footnotes = []
    
    # State tracking
    in_book = False
    in_footnotes = False
    
    for i, line in enumerate(lines):
        line = line.strip()
        if not line:
            continue
        
        # Look for book titles (pattern: number dash Arabic text)
        if re.match(r'^\d+\s*-\s*[ا-ي]', line):
            # Save previous book
            if current_book and current_content:
                main_text = '\n'.join(current_content)
                footnote_text = '\n'.join(current_footnotes)
                
                books[current_book] = {
                    'main_text': main_text,
                    'footnotes': footnote_text
                }
                print(f"  Book: {current_book} - {len(main_text)} chars, {len(footnote_text)} footnote chars")
            
            # Extract clean book title
            clean_title = re.sub(r'\d+\s*-\s*', '', line).strip()
            # Further clean by taking only the first Arabic word (the book name)
            clean_title = re.findall(r'[ا-ي]+', clean_title)[0] if re.findall(r'[ا-ي]+', clean_title) else clean_title
            
            current_book = clean_title
            current_content = [line]  # Keep the original title line
            current_footnotes = []
            in_book = True
            in_footnotes = False
            continue
        
        if current_book:
            # Check for footnote markers - but DON'T modify the content, just detect them
            if (re.match(r'^\d+\s*\)', line) or  # Number followed by parenthesis
                line.startswith('يفسر') or
                line.startswith('يشرح') or
                ('البعض' in line and len(line) > 100)):
                
                in_footnotes = True
            
            # Add line to appropriate section WITHOUT modifying footnote numbers
            if in_footnotes:
                current_footnotes.append(line)
            else:
                current_content.append(line)
    
    # Save last book
    if current_book and current_content:
        main_text = '\n'.join(current_content)
        footnote_text = '\n'.join(current_footnotes)
        
        books[current_book] = {
            'main_text': main_text,
            'footnotes': footnote_text
        }
        print(f"  Book: {current_book} - {len(main_text)} chars, {len(footnote_text)} footnote chars")
    
    return books

def save_books_to_files(books, output_dir="bible_books_txt"):
    """Save each book's main text and footnotes to separate files"""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    print(f"\nSaving books to '{output_dir}' directory...")
    
    saved_count = 0
    for arabic_name, content in books.items():
        english_name = BOOK_MAPPING.get(arabic_name, "Unknown")
        
        # Save main text
        if content['main_text']:
            main_file = os.path.join(output_dir, f"{english_name}.txt")
            with open(main_file, 'w', encoding='utf-8') as f:
                f.write(content['main_text'])
        
        # Save footnotes
        if content['footnotes']:
            footnote_file = os.path.join(output_dir, f"{english_name}_footnote.txt")
            with open(footnote_file, 'w', encoding='utf-8') as f:
                f.write(content['footnotes'])
            
            saved_count += 1
            print(f"  ✓ {english_name}.txt and {english_name}_footnote.txt")
        else:
            print(f"  ✓ {english_name}.txt (no footnotes)")
    
    return saved_count

def analyze_pdf_content(text):
    """Analyze the PDF content to understand its structure"""
    print("\nAnalyzing PDF content structure...")
    
    lines = text.split('\n')
    
    # Look for different types of content
    book_titles = []
    chapter_headers = []
    verses = []
    footnotes = []
    
    for i, line in enumerate(lines[:100]):  # Check first 100 lines
        line = line.strip()
        if not line:
            continue
            
        # Book titles (pattern: number - Arabic text)
        if re.match(r'^\d+\s*-\s*[ا-ي]', line):
            book_titles.append(line)
        
        # Chapter headers
        elif 'الإصحاح' in line:
            chapter_headers.append(line)
        
        # Verses (start with numbers)
        elif re.match(r'^\d+[ا-ي]', line.replace(' ', '')):
            verses.append(line[:100])
        
        # Footnotes
        elif re.match(r'^\d+\s*\)', line) or ('يفسر' in line and len(line) > 50):
            footnotes.append(line[:100])
    
    print(f"Book titles found: {len(book_titles)}")
    for title in book_titles[:5]:
        print(f"  - {title}")
    
    print(f"Chapter headers found: {len(chapter_headers)}")
    print(f"Verses found: {len(verses)}")
    print(f"Footnotes found: {len(footnotes)}")
    
    if footnotes:
        print("Sample footnotes:")
        for i, note in enumerate(footnotes[:3]):
            print(f"  {i+1}. {note}...")

def main():
    # Path to your PDF file
    pdf_file = "old_testament.pdf"  # Change this to your PDF file name
    
    if not os.path.exists(pdf_file):
        print(f"Error: PDF file '{pdf_file}' not found!")
        return
    
    # Extract text from PDF
    pdf_text = extract_text_from_pdf(pdf_file)
    
    # Analyze the content
    analyze_pdf_content(pdf_text)
    
    # Try different extraction methods
    print("\nAttempting book extraction...")
    
    # Method 1: Improved extraction
    books = improved_book_extraction(pdf_text)
    
    if not books:
        print("Method 1 failed. Trying manual extraction...")
        # Method 2: Manual extraction
        books = extract_books_manual(pdf_text)
    
    if books:
        # Save to files
        saved_count = save_books_to_files(books)
        print(f"\n✅ Successfully created files for {saved_count} books!")
        print(f"📁 Output directory: bible_books_txt")
        
        # Show what we extracted
        print("\nExtracted books:")
        for arabic_name in books.keys():
            english_name = BOOK_MAPPING.get(arabic_name, arabic_name)
            print(f"  - {english_name} (from '{arabic_name}')")
    else:
        print("❌ No books could be extracted.")
        print("Please check the PDF structure and adjust the extraction patterns.")

if __name__ == "__main__":
    main()
