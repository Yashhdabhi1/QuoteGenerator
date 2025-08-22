import { LightningElement, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import JSPDF from '@salesforce/resourceUrl/JSPDF';
import JSPDF_AUTOTABLE from '@salesforce/resourceUrl/JSPDF_AUTOTABLE';
import getProducts from '@salesforce/apex/QuoteController.getProducts';
import createQuote from '@salesforce/apex/QuoteController.createQuote';
import saveQuoteFile from '@salesforce/apex/QuoteController.saveQuoteFile';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class QuoteGenerator extends LightningElement {
    @track filteredProducts = [];
    @track selectedProducts = [];
    @track lineItems = [];
    @track totalAmount = 0;
    @track searchKey = '';
    jsPDFInitialized = false;

    currentStep = "1";

    get isStep1() { return this.currentStep === "1"; }
    get isStep2() { return this.currentStep === "2"; }
    get isStep3() { return this.currentStep === "3"; }

    // Load jsPDF and jspdf-autotable when the component is connected
    connectedCallback() {
        if (!this.jsPDFInitialized) {
            Promise.all([
                loadScript(this, JSPDF),
                loadScript(this, JSPDF_AUTOTABLE)
            ])
                .then(() => {
                    this.jsPDFInitialized = true;

                    // Register autoTable with jsPDF
                    const { jsPDF } = window.jspdf;
                    window.jsPDF = window.jspdf.jsPDF;
                    // Ensure global
                    window.jspdfAutoTable = window.jspdfAutoTable || window.jspdf?.autoTable;

                    // Attach if not already available
                    if (window.jspdfAutoTable) {
                        jsPDF.API.autoTable = window.jspdfAutoTable;
                    }
                })
                .catch(error => {
                    this.showToast('Error', 'Failed to load PDF libraries', 'error');
                });
        }
    }


    async handleSearchKeyUp(event) {
        if (event.keyCode === 13) {
            this.searchKey = event.target.value.trim().toLowerCase();
            if (!this.searchKey) {
                this.filteredProducts = [];
                return;
            }
            try {
                const data = await getProducts();
                this.filteredProducts = data
                    .filter(entry => entry.Product2.Name.toLowerCase().includes(this.searchKey))
                    .map(entry => ({
                        Id: entry.Product2.Id,
                        Name: entry.Product2.Name,
                        UnitPrice: entry.UnitPrice,
                        quantity: 0,
                        totalPrice: 0,
                        cssClass: 'product-card slds-box slds-box_link slds-p-around_medium'
                    }));
            } catch (error) {
                this.showToast('Error', error.body?.message || error.message, 'error');
            }
        }
    }

    handleSelectProduct(event) {
        if (event.type === 'keydown' && !['Enter', ' '].includes(event.key)) return;

        const productId = event.currentTarget.dataset.id;
        const existingIndex = this.selectedProducts.findIndex(p => p.Id === productId);

        if (existingIndex >= 0) {
            this.selectedProducts.splice(existingIndex, 1);
        } else {
            const product = this.filteredProducts.find(p => p.Id === productId);
            if (product) {
                this.selectedProducts = [...this.selectedProducts, { ...product }];
            }
        }

        this.filteredProducts = this.filteredProducts.map(p => ({
            ...p,
            cssClass: 'product-card slds-box slds-box_link slds-p-around_medium' +
                (this.selectedProducts.find(sp => sp.Id === p.Id) ? ' selected' : '')
        }));
    }

    handleQuantityChange(event) {
        const index = event.target.dataset.index;
        const quantity = parseInt(event.target.value) || 0;
        this.selectedProducts[index] = {
            ...this.selectedProducts[index],
            quantity,
            totalPrice: quantity * this.selectedProducts[index].UnitPrice
        };
        this.selectedProducts = [...this.selectedProducts];
    }

    goToStep1() { this.currentStep = "1"; }
    goToStep2() { this.currentStep = "2"; }
    goToStep3() {
        this.lineItems = this.selectedProducts
            .filter(p => p.quantity > 0)
            .map(p => ({
                productId: p.Id,
                productName: p.Name,
                quantity: p.quantity,
                unitPrice: p.UnitPrice,
                totalPrice: p.totalPrice
            }));
        this.totalAmount = this.lineItems.reduce((sum, i) => sum + i.totalPrice, 0);
        this.currentStep = "3";
    }

    async handleSaveQuote() {
        try {
            const formattedLineItems = this.lineItems.map(item => ({
                productId: item.productId,
                productName: item.productName,
                quantity: item.quantity,
                unitPrice: item.unitPrice
            }));
            const quoteId = await createQuote({ lineItems: formattedLineItems });
            this.showToast('Success', `Quote created with ID: ${quoteId}`, 'success');

            // Generate PDF
            this.handleGeneratePDF();

            // Reset wizard
            this.filteredProducts = [];
            this.selectedProducts = [];
            this.lineItems = [];
            this.totalAmount = 0;
            this.searchKey = '';
            this.currentStep = "1";
        } catch (error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
        }
    }

        handleGeneratePDF() {
        if (!this.jsPDFInitialized) {
            this.showToast('Error', 'PDF libraries not loaded', 'error');
            return;
        }

        const { jsPDF } = window.jspdf;
        const doc = new jsPDF();

        // 🔹 Title
        doc.setFontSize(18);
        doc.setFont("helvetica", "bold");
        doc.text('Quote Summary', 105, 15, { align: "center" });

        // 🔹 Meta Info
        doc.setFontSize(11);
        doc.setFont("helvetica", "normal");
        doc.text(`Date: ${new Date().toLocaleDateString()}`, 20, 25);
        doc.text(`Prepared By: Salesforce Quote Generator`, 20, 32);

        // 🔹 Table
        const headers = [['Product', 'Quantity', 'Unit Price', 'Total Price']];
        const body = this.lineItems.map(item => [
            item.productName,
            item.quantity.toString(),
            `$${item.unitPrice.toFixed(2)}`,
            `$${item.totalPrice.toFixed(2)}`
        ]);

        // Add grand total row
        body.push([
            { content: 'Grand Total', colSpan: 3, styles: { halign: 'right', fontStyle: 'bold' } },
            { content: `$${this.totalAmount.toFixed(2)}`, styles: { fontStyle: 'bold' } }
        ]);

        doc.autoTable({
            head: headers,
            body: body,
            startY: 40,
            theme: 'grid',
            styles: { fontSize: 10, cellPadding: 4 },
            headStyles: { fillColor: [41, 128, 185], textColor: 255, fontStyle: 'bold' }, // Blue header
            alternateRowStyles: { fillColor: [245, 245, 245] }, // Light grey rows
            columnStyles: {
                0: { cellWidth: 70 }, // Product
                1: { cellWidth: 30, halign: 'center' }, // Qty
                2: { cellWidth: 40, halign: 'right' }, // Unit Price
                3: { cellWidth: 40, halign: 'right' }  // Total Price
            },
            margin: { left: 20, right: 20 }
        });

        // 🔹 Footer
        const finalY = doc.lastAutoTable.finalY || 60;
        doc.setFontSize(9);
        doc.setTextColor(100);
        doc.text('Thank you for your business!', 105, finalY + 15, { align: "center" });

        // 🔹 Save
        doc.save(`Quote_${new Date().toISOString().split('T')[0]}.pdf`);
    }


    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}