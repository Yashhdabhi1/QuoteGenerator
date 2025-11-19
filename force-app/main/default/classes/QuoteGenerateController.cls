public with sharing class QuoteGenerateController {
    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getProducts() {
        return [
            SELECT Product2.Id, Product2.Name, UnitPrice, IsActive 
            FROM PricebookEntry 
            WHERE Pricebook2.IsStandard = true 
            AND Product2.IsActive = true 
            AND IsActive = true
        ];
    }

    // Wrapper class to return both Id and Name
    public class QuoteResponse {
        @AuraEnabled public Id Id { get; set; }
        @AuraEnabled public String Name { get; set; }
    }

    @AuraEnabled
    public static QuoteResponse createQuote(List<Map<String, Object>> lineItems) {
        if (lineItems == null || lineItems.isEmpty()) {
            throw new AuraHandledException('No line items provided.');
        }

        Quote__c quote = new Quote__c(Status__c = 'Draft', Total_Amount__c = 0);
        insert quote;

        Decimal total = 0;
        List<QuoteLineItem__c> quoteLineItems = new List<QuoteLineItem__c>();

        for (Map<String, Object> item : lineItems) {
            Id productId = (Id)item.get('productId');
            Integer quantity = Integer.valueOf(item.get('quantity'));
            Decimal unitPrice = Decimal.valueOf(String.valueOf(item.get('unitPrice')));
            String productName = String.valueOf(item.get('productName'));

            if (quantity <= 0) continue;

            QuoteLineItem__c lineItem = new QuoteLineItem__c(
                Quote__c = quote.Id,
                Product__c = productId,
                Quantity__c = quantity,
                Unit_Price__c = unitPrice,
                Name = productName
            );
            quoteLineItems.add(lineItem);
            total += quantity * unitPrice;
        }

        if (quoteLineItems.isEmpty()) {
            throw new AuraHandledException('No valid line items to process.');
        }

        insert quoteLineItems;

        quote.Total_Amount__c = total;
        update quote;

        // Query the record again to get Auto Number Name
        Quote__c q = [
            SELECT Id, Name
            FROM Quote__c
            WHERE Id = :quote.Id
            LIMIT 1
        ];

        QuoteResponse resp = new QuoteResponse();
        resp.Id = q.Id;
        resp.Name = q.Name; // Auto-number like Quote-0001
        return resp;
    }
}