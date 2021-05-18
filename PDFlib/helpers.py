from PDFlib.TET import TET
from lxml import etree
license_key = 'L500902-010300-742594-KJZM72-NMYX52'

class TETDocument:
    def __init__(self, file, doc_options, page_options):
        self.doc_options = doc_options
        self.page_options = page_options

        self.file = file

        self._handle = TET()
        self._handle.set_option(f"license={license_key}")

        self._doc = self.open_document()
    
    def open_document(self):
        doc = self._handle.open_document(self.file, self.doc_options)
        if doc == -1: raise Exception(self._handle.get_errmsg())
        self._doc = doc
        return self._doc
    
    def close_document(self):
        self._handle.close_document(self._doc)
    
    def reopen_document(self):
        self.close_document()
        self.open_document()

    @property
    def total_pages(self):
        return int(self._handle.pcos_get_number(self._doc, "length:pages"))
    
    def get_tetml(self, pages=None):
        for page_num in range(1, self.total_pages):
            if not pages or page_num in pages:
                self._handle.process_page(self._doc, page_num, self.page_options)
            
        self._handle.process_page(self._doc, 0, "tetml={trailer}")
        
        self.tetml = self._handle.get_tetml(self._doc, "")
        self.tree = etree.fromstring(self.tetml)
        self.reopen_document()
        return self.tree