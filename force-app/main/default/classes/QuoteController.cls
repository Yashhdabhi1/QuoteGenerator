public with sharing class QuoteController {
    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getProducts() {
        return [SELECT Product2.Id, Product2.Name, UnitPrice, IsActive 
                FROM PricebookEntry 
                WHERE Pricebook2.IsStandard = true 
                AND Product2.IsActive = true 
                AND IsActive = true];
    }

    @AuraEnabled
    public static Id createQuote(List<Map<String, Object>> lineItems) {
        if (lineItems == null || lineItems.isEmpty()) {
            System.debug('Throwing exception: No line items provided.');
            throw new AuraHandledException('No line items provided.');
        }

        System.debug('Incoming lineItems: ' + JSON.serialize(lineItems));

        Quote__c quote = new Quote__c(Status__c = 'Draft', Total_Amount__c = 0);
        insert quote;

        Decimal total = 0;
        List<QuoteLineItem__c> quoteLineItems = new List<QuoteLineItem__c>();
        for (Map<String, Object> item : lineItems) {
            Object productIdObj = item.get('productId');
            Object quantityObj = item.get('quantity');
            Object unitPriceObj = item.get('unitPrice');
            Object productNameObj = item.get('productName');

            if (productIdObj == null || quantityObj == null || unitPriceObj == null || productNameObj == null) {
                System.debug('Throwing exception: Missing required fields in line item: ' + JSON.serialize(item));
                throw new AuraHandledException('Missing required fields in line item: ' + JSON.serialize(item));
            }

            Id productId = (Id)productIdObj;
            Integer quantity = Integer.valueOf(quantityObj);
            Decimal unitPrice = Decimal.valueOf(String.valueOf(unitPriceObj));
            String productName = String.valueOf(productNameObj);

            if (quantity <= 0) {
                continue; 
            }

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
            System.debug('Throwing exception: No valid line items to process.');
            throw new AuraHandledException('No valid line items to process.');
        }

        insert quoteLineItems;
        quote.Total_Amount__c = total;
        update quote;

        return quote.Id;
    }
}