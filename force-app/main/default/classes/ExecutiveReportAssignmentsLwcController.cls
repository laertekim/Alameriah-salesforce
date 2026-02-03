public with sharing class ExecutiveReportAssignmentsLwcController {
    public class RowDTO {
        @AuraEnabled public String col1;
        @AuraEnabled public String col2;
        @AuraEnabled public String col3;
        @AuraEnabled public Decimal col4;
        @AuraEnabled public Integer col5;
    }

    public class SavePdfResult {
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public Id contentVersionId;
        @AuraEnabled public String fileName;
    }

    @AuraEnabled(cacheable=true)
    public static List<Project_Assignment__c> getAssignments(Id executiveReportId) {
        
        List<Project_Assignment__c> assignments = [
            SELECT
                Id,
                Name,
                Item__c,
                Assignment_Description__c,
                Next_Action_Decision_Required__c,
                Action_By2__c,
                Target_Status__c,
                Priority_Notes__c,
                Project__r.Name
            FROM Project_Assignment__c
            WHERE Executive_Report__c = :executiveReportId
            ORDER BY Project__r.Name, Item__c, Name
        ];
        
        SObjectAccessDecision decision =
            Security.stripInaccessible(AccessType.READABLE, assignments);

        return (List<Project_Assignment__c>) decision.getRecords();
    }

    @AuraEnabled
    public static Id savePdfFromLwc(Id reportId, String base64Data, String fileName) {
        try {
            if (reportId == null) {
                throw new AuraHandledException('reportId é obrigatório.');
            }
            
            if (String.isBlank(base64Data)) {
                throw new AuraHandledException('base64Data é obrigatório.');
            }
            
            if (String.isBlank(fileName)) {
                fileName = 'Executive_Report_Assignments_' + Date.today().format() + '.pdf';
            }
            
            if (!fileName.toLowerCase().endsWith('.pdf')) {
                fileName += '.pdf';
            }

            Blob pdfBlob = EncodingUtil.base64Decode(base64Data);

            ContentVersion cv = new ContentVersion();
            cv.Title = fileName.replace('.pdf','');
            cv.PathOnClient = fileName;
            cv.VersionData = pdfBlob;
            cv.FirstPublishLocationId = reportId; // <-- faz aparecer na Related List "Files"
            insert cv;

            return cv.Id; // ContentVersionId
        } catch (Exception e) {
            throw new AuraHandledException('Error saving PDF to Files: ' + e.getMessage());
        }
    }
}