This `combined` branch of `super_editor` fork contains the following extended features as WIP:

- mobile support
  - addition of a Document Interactor for touch devices and virtual keyboard (WIP) 
  - see: [mobile](https://github.com/osaxma/super_editor/tree/mobile) branch
   
  https://user-images.githubusercontent.com/46427323/116639257-c5821500-a970-11eb-8b4d-718efae5cd47.mp4

- paragraph text direction is determined by language 
   - The text direction of a paragraph is determined by the first non-whitespace character (i.e. LTR vs RTL). 
   - see: [bidi_pargraph](https://github.com/osaxma/super_editor/tree/bidi_pargraph) branch
   <img width="702" alt="Screen Shot 2021-04-14 at 5 50 05 PM" src="https://user-images.githubusercontent.com/46427323/114731407-66a28600-9d4a-11eb-879b-452cee5ef498.png">

  
- Document Viewer
  - a read-only view of a Document. 
  - see: [1090d43](https://github.com/osaxma/super_editor/commit/1090d4390fd8b8533b25a17c467b3cb81ee32692) commit. 



---
Note:
The goal is to formalize these features as proposals and push them upstream when the appropriate time comes. 