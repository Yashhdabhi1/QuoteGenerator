# Quote Generator Lightning Web Component (LWC)

A dynamic **Salesforce Lightning Web Component** for generating quotes with product selection, quantity input, and PDF export functionality. This component provides a seamless multi-step wizard interface for sales teams to search products, set quantities, review totals, and save quotes.

---

## Features

1. **Multi-Step Wizard**  
   - Step 1: Search & filter products  
   - Step 2: Add quantities to selected products  
   - Step 3: Review quote summary and total amount  

2. **Dynamic Product Selection**  
   - Click to select/unselect products  
   - Border highlights in red when selected  

3. **Quantity Management**  
   - Enter product quantities  
   - Dynamic calculation of total prices  

4. **Quote Summary**  
   - Displays selected products with quantities, unit prices, and total prices  
   - Total quote amount automatically calculated  

5. **Save Quote & PDF Generation**  
   - Saves quote via Apex controller  
   - Optionally generates a PDF of the quote  

6. **Responsive UI**  
   - Uses Salesforce Lightning Design System (SLDS)  
   - Mobile-friendly and accessible  

---

## Usage

1. **Step 1: Search & Filter Products**  
   - Type a keyword and press **Enter** to filter products.  
   - Click a product to select it (border turns red). Click again to unselect.  

2. **Step 2: Add Quantity**  
   - Input quantities for the selected products.  

3. **Step 3: Quote Summary**  
   - Review all selected products and totals.  
   - Click **Save Quote & Generate PDF** to save in Salesforce and optionally download a PDF.  

---

## Dependencies

- Salesforce Lightning Web Components  
- Apex Controller (`QuoteController`) with methods:
  - `getProducts()` – retrieves product data  
  - `createQuote(lineItems)` – saves the quote  

- [SLDS](https://www.lightningdesignsystem.com/) for styling  
- Optional: jsPDF for client-side PDF generation  

---

## File Structure

```
force-app/
└── main/
    └── default/
        └── classes/
                ├── QuoteController.cls
                └── QuoteController.cls-meta.xml 
        └── lwc/
            └── quoteGenerator/
                ├── quoteGenerator.html
                ├── quoteGenerator.js
                └── quoteGenerator.css
        └── staticresources/
                ├── JSPDF.js
                ├── JSPDF.resource-meta.xml
                ├── JSPDF_AUTOTABLE.js
                └── JSPDF_AUTOTABLE.resource-meta.xml
            
```

---

## Screenshots

**Step 1: Search & Select Products**  
<img width="1353" height="503" alt="QG1" src="https://github.com/user-attachments/assets/5a4f5693-46ef-4f8a-8157-d2071d09430d" />


**Step 2: Add Quantities**  
<img width="1350" height="536" alt="QG2" src="https://github.com/user-attachments/assets/27c4f031-48e5-4068-8dbd-63800510db04" />


**Step 3: Quote Summary**  
<img width="1349" height="390" alt="QG3" src="https://github.com/user-attachments/assets/3b0aebae-541f-4585-b436-f2452b6e70f0" />


---

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.  

---

## License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.  

---

### Optional Enhancements

- Smooth border transition animation when selecting/unselecting products  
- Integration with Salesforce CPQ for advanced pricing  
- Support for multiple currencies  
- Enhanced PDF formatting and styling

