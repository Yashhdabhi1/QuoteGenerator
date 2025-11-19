@IsTest(SeeAllData=false)
private class QuoteGenerateControllerTest {
    @TestSetup
    static void makeData() {
        // Create a Product and a PricebookEntry in the standard pricebook as baseline test data.
        Product2 prod = new Product2(Name = 'Test Generator 750kW', IsActive = true);
        insert prod;

        Id stdPbId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id   = prod.Id,
            UnitPrice    = 5000,
            IsActive     = true
        );
        insert pbe;
    }

    @IsTest
    static void testGetProductsReturnsEntries() {
        // Ensure Standard Pricebook is active
        Id stdPbId = Test.getStandardPricebookId();
        Pricebook2 stdPb = [SELECT Id, IsActive FROM Pricebook2 WHERE Id = :stdPbId LIMIT 1];
        if (!stdPb.IsActive) {
            stdPb.IsActive = true;
            update stdPb;
        }

        // Create an active product
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        // Create an active pricebook entry in the standard pricebook
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id   = prod.Id,
            UnitPrice    = 100,
            IsActive     = true
        );
        insert pbe;

        // Act
        List<PricebookEntry> products = QuoteGenerateController.getProducts();

        // Assert
        System.assertNotEquals(null, products, 'getProducts should not return null.');
        System.assert(products.size() > 0, 'Expected at least one PricebookEntry from getProducts.');
        PricebookEntry fetched = products[0];
        System.assertNotEquals(null, fetched.Product2Id, 'Product2Id should be populated.');
        System.assertNotEquals(null, fetched.UnitPrice, 'UnitPrice should be populated.');
        System.assertEquals(true, fetched.IsActive, 'PricebookEntry should be active.');
    }

    @IsTest
    static void testCreateQuoteSuccess() {
        Product2 prod = [SELECT Id, Name FROM Product2 LIMIT 1];

        Map<String, Object> item = new Map<String, Object>{
            'productId'   => prod.Id,
            'quantity'    => 3,
            'unitPrice'   => 10.50,
            'productName' => prod.Name
        };
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{ item };

        Test.startTest();
            QuoteGenerateController.QuoteResponse resp = QuoteGenerateController.createQuote(lineItems);
        Test.stopTest();

        System.assertNotEquals(null, resp);
        System.assertNotEquals(null, resp.Id);
        System.assertNotEquals(null, resp.Name);

        Quote__c q = [SELECT Id, Total_Amount__c, Status__c FROM Quote__c WHERE Id = :resp.Id LIMIT 1];
        System.assertEquals('Draft', q.Status__c);

        Decimal expected = Decimal.valueOf('31.5'); // 3 * 10.5
        System.assertEquals(expected, q.Total_Amount__c, 'Total_Amount__c should equal 31.5');

        List<QuoteLineItem__c> lines = [SELECT Id, Quantity__c, Unit_Price__c, Product__c, Name FROM QuoteLineItem__c WHERE Quote__c = :q.Id];
        System.assertEquals(1, lines.size());
        QuoteLineItem__c li = lines[0];
        System.assertEquals(3, Integer.valueOf(String.valueOf(li.Quantity__c)));
        System.assertEquals(Decimal.valueOf('10.5'), li.Unit_Price__c);
    }

    @IsTest
    static void testCreateQuoteNullOrEmptyThrows() {
        // Null input - do not use Test.startTest/stopTest here to avoid leaving a started test open if exception is thrown.
        Boolean threw = false;
        try {
            QuoteGenerateController.createQuote(null);
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Expected AuraHandledException for null lineItems');

        // Empty list input
        threw = false;
        try {
            QuoteGenerateController.createQuote(new List<Map<String, Object>>());
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Expected AuraHandledException for empty list lineItems');
    }

    @IsTest
    static void testCreateQuoteNoValidLineItemsThrows() {
        Product2 prod = [SELECT Id, Name FROM Product2 LIMIT 1];

        Map<String, Object> itemZero = new Map<String, Object>{
            'productId'   => prod.Id,
            'quantity'    => 0,
            'unitPrice'   => 5,
            'productName' => prod.Name
        };
        List<Map<String, Object>> items = new List<Map<String, Object>>{ itemZero };

        // Don't use Test.startTest/stopTest here for same reason as above
        Boolean threw = false;
        try {
            QuoteGenerateController.createQuote(items);
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Expected AuraHandledException when all quantities are non-positive.');
    }

    @IsTest
    static void testSavePdfSuccessCreatesContentVersion() {
        Quote__c q = new Quote__c(Status__c = 'Draft', Total_Amount__c = 0);
        insert q;

        Blob testBlob = Blob.valueOf('This is a test PDF content');
        String base64 = EncodingUtil.base64Encode(testBlob);
        String fileName = 'TestQuote.pdf';

        Test.startTest();
            QuotePdfController.savePdf(q.Id, base64, fileName);
        Test.stopTest();

        String expectedTitle = fileName.replace('.pdf', '');
        List<ContentVersion> cvs = [
            SELECT Id, Title, PathOnClient, FirstPublishLocationId
            FROM ContentVersion
            WHERE Title = :expectedTitle
            AND FirstPublishLocationId = :q.Id
            LIMIT 5
        ];
        System.assert(cvs.size() > 0, 'A ContentVersion should have been created.');
        ContentVersion cv = cvs[0];
        System.assertEquals(expectedTitle, cv.Title);
        System.assertEquals(q.Id, cv.FirstPublishLocationId);
    }

    @IsTest
    static void testSavePdfInvalidBase64Throws() {
        Quote__c q = new Quote__c(Status__c = 'Draft', Total_Amount__c = 0);
        insert q;

        String badBase64 = 'not-a-valid-base64@@@';
        String fileName = 'Bad.pdf';

        Boolean threw = false;
        try {
            // Avoid Test.startTest/stopTest to prevent the "Testing already started" issue when exception is thrown.
            QuotePdfController.savePdf(q.Id, badBase64, fileName);
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Expected AuraHandledException due to invalid base64 input.');
    }
}