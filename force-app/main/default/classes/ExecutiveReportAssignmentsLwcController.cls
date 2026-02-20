public with sharing class ExecutiveReportAssignmentsLwcController {
    public class RowDTO {
        @AuraEnabled public String col1;
        @AuraEnabled public String col2;
        @AuraEnabled public String col3;
        @AuraEnabled public Decimal col4;
        @AuraEnabled public Integer col5;
    }

    public class AttachmentInfo {
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public String fileName;
        @AuraEnabled public String fileExtension;
        @AuraEnabled public Integer fileSize;
        @AuraEnabled public DateTime createdDate;
    }

    public class AssignmentWrapper {
        @AuraEnabled public Project_Assignment__c assignment;
        @AuraEnabled public List<AttachmentInfo> attachments;
    }

    public class SavePdfResult {
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public Id contentVersionId;
        @AuraEnabled public String fileName;
    }

    @AuraEnabled(cacheable=false)
    public static List<AssignmentWrapper> getAssignments(Id executiveReportId) {
        if (executiveReportId == null) {
            throw new AuraHandledException('Executive Report ID is required.');
        }
        
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
            ORDER BY CreatedDate, Project__r.Name, Item__c
        ];
        
        SObjectAccessDecision decision =
            Security.stripInaccessible(AccessType.READABLE, assignments);
        
        List<Project_Assignment__c> stripped = (List<Project_Assignment__c>) decision.getRecords();
        
        // Get record IDs for attachment query
        Set<Id> recordIds = new Set<Id>();
        for (Project_Assignment__c pa : stripped) {
            recordIds.add(pa.Id);
        }
        
        // Query for attachments
        Map<Id, List<AttachmentInfo>> attachmentMap = new Map<Id, List<AttachmentInfo>>();
        if (!recordIds.isEmpty()) {
            List<ContentDocumentLink> cdLinks = [
                SELECT ContentDocumentId, LinkedEntityId, ContentDocument.Title, 
                       ContentDocument.FileExtension, ContentDocument.ContentSize,
                       ContentDocument.CreatedDate
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :recordIds
                WITH SECURITY_ENFORCED
                ORDER BY ContentDocument.CreatedDate DESC
            ];

            SObjectAccessDecision cdlDecision =
                Security.stripInaccessible(AccessType.READABLE, cdLinks);
            List<ContentDocumentLink> strippedCdLinks =
                (List<ContentDocumentLink>) cdlDecision.getRecords();
            
            for (ContentDocumentLink cdl : strippedCdLinks) {
                if (!attachmentMap.containsKey(cdl.LinkedEntityId)) {
                    attachmentMap.put(cdl.LinkedEntityId, new List<AttachmentInfo>());
                }
                
                AttachmentInfo attInfo = new AttachmentInfo();
                attInfo.contentDocumentId = cdl.ContentDocumentId;
                
                String fullFileName = cdl.ContentDocument.Title;
                if (cdl.ContentDocument.FileExtension != null && !fullFileName.toLowerCase().endsWith('.' + cdl.ContentDocument.FileExtension.toLowerCase())) {
                    fullFileName = fullFileName + '.' + cdl.ContentDocument.FileExtension;
                }
                attInfo.fileName = fullFileName;
                attInfo.fileExtension = cdl.ContentDocument.FileExtension;
                attInfo.fileSize = cdl.ContentDocument.ContentSize != null ? 
                                   Integer.valueOf(cdl.ContentDocument.ContentSize) : 0;
                attInfo.createdDate = cdl.ContentDocument.CreatedDate;
                
                attachmentMap.get(cdl.LinkedEntityId).add(attInfo);
            }
        }
        
        // Wrap assignments with attachments
        List<AssignmentWrapper> result = new List<AssignmentWrapper>();
        for (Project_Assignment__c pa : stripped) {
            AssignmentWrapper wrapper = new AssignmentWrapper();
            wrapper.assignment = pa;
            wrapper.attachments = attachmentMap.containsKey(pa.Id) ? attachmentMap.get(pa.Id) : new List<AttachmentInfo>();
            result.add(wrapper);
        }
        
        return result;
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
