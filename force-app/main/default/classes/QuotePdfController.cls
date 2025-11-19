public with sharing class QuotePdfController {

    @AuraEnabled
    public static void savePdf(Id quoteId, String pdfBase64, String fileName) {
        try {
            Blob pdfBlob = EncodingUtil.base64Decode(pdfBase64);

            ContentVersion cv = new ContentVersion(
                Title = fileName.replace('.pdf', ''),
                PathOnClient = fileName,
                VersionData = pdfBlob,
                FirstPublishLocationId = quoteId  // This links it to Quote → appears in Files
            );
            insert cv;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to save PDF: ' + e.getMessage());
        }
    }
}