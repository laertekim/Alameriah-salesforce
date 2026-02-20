public with sharing class ProjectAssignmentManagerController {

    // ============================================================
    // DTOs
    // ============================================================
    public class AssignmentRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String paNumber;
        @AuraEnabled public Decimal item;
        @AuraEnabled public String nextAction;
        @AuraEnabled public String assignment;
        @AuraEnabled public String actionBy;
        @AuraEnabled public Date targetDate;
        @AuraEnabled public String status;
        @AuraEnabled public Id projectId;
        @AuraEnabled public String projectName;
        @AuraEnabled public Integer sortOrder;
        @AuraEnabled public List<AttachmentInfo> attachments;
    }

    public class AttachmentInfo {
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public String fileName;
        @AuraEnabled public String fileExtension;
        @AuraEnabled public Integer fileSize;
        @AuraEnabled public DateTime createdDate;
    }

    public class LookupOption {
        @AuraEnabled public Id value;
        @AuraEnabled public String label;

        public LookupOption(Id value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    public class SaveResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Id recordId;
    }

    // ============================================================
    // Get all assignments for Executive Report
    // ============================================================
    @AuraEnabled(cacheable=false)
    public static List<AssignmentRow> getAssignmentsByExecutiveReport(Id executiveReportId) {
        if (executiveReportId == null) {
            throw new AuraHandledException('Executive Report ID is required.');
        }

        List<Project_Assignment__c> records = [
            SELECT Id,
                   Name,
                   Item__c,
                   Next_Action_Decision_Required__c,
                   Assignment_Description__c,
                   Action_By2__c,
                   Target_Status__c,
                   Priority_Notes__c,
                   Project__c,
                   Project__r.Name,
                   Sort_Order__c
            FROM Project_Assignment__c
            WHERE Executive_Report__c = :executiveReportId
            ORDER BY CreatedDate, Project__r.Name, Item__c
        ];

        SObjectAccessDecision sd = Security.stripInaccessible(AccessType.READABLE, records);
        List<SObject> stripped = sd.getRecords();

        // Get record IDs for attachment query
        Set<Id> recordIds = new Set<Id>();
        for (SObject s : stripped) {
            recordIds.add(s.Id);
        }

        // Query for attachments (ContentDocumentLinks)
        Map<Id, List<AttachmentInfo>> attachmentMap = new Map<Id, List<AttachmentInfo>>();
        if (!recordIds.isEmpty()) {
            List<ContentDocumentLink> cdLinks = [
                SELECT ContentDocumentId, LinkedEntityId, ContentDocument.Title, 
                       ContentDocument.FileExtension, ContentDocument.ContentSize,
                       ContentDocument.CreatedDate
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :recordIds
                ORDER BY ContentDocument.CreatedDate DESC
            ];

            System.debug('Found ' + cdLinks.size() + ' ContentDocumentLinks');

            for (ContentDocumentLink cdl : cdLinks) {
                if (!attachmentMap.containsKey(cdl.LinkedEntityId)) {
                    attachmentMap.put(cdl.LinkedEntityId, new List<AttachmentInfo>());
                }
                
                AttachmentInfo attInfo = new AttachmentInfo();
                attInfo.contentDocumentId = cdl.ContentDocumentId;
                
                // Build full file name with extension
                String fullFileName = cdl.ContentDocument.Title;
                if (cdl.ContentDocument.FileExtension != null && !fullFileName.toLowerCase().endsWith('.' + cdl.ContentDocument.FileExtension.toLowerCase())) {
                    fullFileName = fullFileName + '.' + cdl.ContentDocument.FileExtension;
                }
                attInfo.fileName = fullFileName;
                
                attInfo.fileExtension = cdl.ContentDocument.FileExtension;
                attInfo.fileSize = cdl.ContentDocument.ContentSize != null ? 
                                   Integer.valueOf(cdl.ContentDocument.ContentSize) : 0;
                attInfo.createdDate = cdl.ContentDocument.CreatedDate;
                
                System.debug('Attachment: ' + attInfo.fileName + ' linked to ' + cdl.LinkedEntityId);
                
                attachmentMap.get(cdl.LinkedEntityId).add(attInfo);
            }
        }

        System.debug('Attachment map size: ' + attachmentMap.size());

        List<AssignmentRow> results = new List<AssignmentRow>();
        for (SObject s : stripped) {
            Project_Assignment__c rec = (Project_Assignment__c) s;
            AssignmentRow row = new AssignmentRow();
            row.id = rec.Id;
            row.paNumber = rec.Name;
            row.item = rec.Item__c;
            row.nextAction = rec.Next_Action_Decision_Required__c;
            row.assignment = rec.Assignment_Description__c;
            row.actionBy = rec.Action_By2__c;
            row.targetDate = rec.Target_Status__c;
            row.status = rec.Priority_Notes__c;
            row.projectId = rec.Project__c;
            row.projectName = rec.Project__r != null ? rec.Project__r.Name : null;
            row.sortOrder = rec.Sort_Order__c != null ? rec.Sort_Order__c.intValue() : null;
            row.attachments = attachmentMap.containsKey(rec.Id) ? 
                              attachmentMap.get(rec.Id) : new List<AttachmentInfo>();
            results.add(row);
        }

        return results;
    }

    // ============================================================
    // Get Status Picklist Values
    // ============================================================
    @AuraEnabled(cacheable=true)
    public static List<String> getStatusPicklistValues() {
        Schema.DescribeFieldResult dfr = Project_Assignment__c.Priority_Notes__c.getDescribe();
        List<String> vals = new List<String>();
        for (Schema.PicklistEntry ple : dfr.getPicklistValues()) {
            if (ple.isActive()) vals.add(ple.getValue());
        }
        return vals;
    }

    // ============================================================
    // Search Projects (for dropdown)
    // ============================================================
    @AuraEnabled(cacheable=true)
    public static List<LookupOption> searchProjects(String searchTerm) {
        String term = normalizeTerm(searchTerm);
        
        List<Project__c> recs;
        if (String.isBlank(term)) {
            recs = [
                SELECT Id, Name 
                FROM Project__c 
                ORDER BY Name 
                LIMIT 50
            ];
        } else {
            String searchPattern = '%' + term + '%';
            recs = [
                SELECT Id, Name 
                FROM Project__c 
                WHERE Name LIKE :searchPattern
                ORDER BY Name 
                LIMIT 50
            ];
        }
        
        return toOptions(recs);
    }

    // ============================================================
    // Get next Item number for a Project
    // ============================================================
    @AuraEnabled
    public static Decimal getNextItemNumber(Id executiveReportId, Id projectId) {
        if (executiveReportId == null || projectId == null) {
            return 1;
        }

        List<AggregateResult> results = [
            SELECT MAX(Item__c) maxItem
            FROM Project_Assignment__c
            WHERE Executive_Report__c = :executiveReportId
            AND Project__c = :projectId
        ];

        if (results.isEmpty() || results[0].get('maxItem') == null) {
            return 1;
        }

        Decimal maxItem = (Decimal) results[0].get('maxItem');
        return maxItem + 1;
    }

    // ============================================================
    // Get next PA Number
    // ============================================================
    @AuraEnabled
    public static String getNextPANumber() {
        List<Project_Assignment__c> lastPA = [
            SELECT Name
            FROM Project_Assignment__c
            WHERE Name LIKE 'PA #%'
            ORDER BY Name DESC
            LIMIT 1
        ];

        Integer nextNumber = 1;
        
        if (!lastPA.isEmpty() && lastPA[0].Name != null) {
            String lastPAName = lastPA[0].Name;
            String numberPart = lastPAName.replace('PA #', '').trim();
            try {
                Integer lastNumber = Integer.valueOf(numberPart);
                nextNumber = lastNumber + 1;
            } catch (Exception e) {
                nextNumber = 1;
            }
        }

        String numberStr = String.valueOf(nextNumber);
        while (numberStr.length() < 5) {
            numberStr = '0' + numberStr;
        }
        return 'PA #' + numberStr;
    }

    // ============================================================
    // Create new assignment
    // ============================================================
    @AuraEnabled
    public static SaveResult createAssignment(
        Id executiveReportId,
        Id projectId,
        String paNumber,
        Decimal item,
        String nextAction,
        String assignment,
        String actionBy,
        Date targetDate,
        String status,
        Integer sortOrder
    ) {
        SaveResult result = new SaveResult();
        
        if (executiveReportId == null) {
            result.success = false;
            result.errorMessage = 'Executive Report ID is required.';
            return result;
        }

        if (projectId == null) {
            result.success = false;
            result.errorMessage = 'Project is required.';
            return result;
        }

        Project_Assignment__c rec = new Project_Assignment__c(
            Executive_Report__c = executiveReportId,
            Project__c = projectId,
            Name = paNumber,
            Item__c = item,
            Next_Action_Decision_Required__c = nextAction,
            Assignment_Description__c = assignment,
            Action_By2__c = actionBy,
            Target_Status__c = targetDate,
            Priority_Notes__c = status,
            Sort_Order__c = sortOrder
        );

        SObjectAccessDecision sd = Security.stripInaccessible(
            AccessType.CREATABLE, 
            new List<Project_Assignment__c>{ rec }
        );
        List<SObject> stripped = sd.getRecords();
        
        if (stripped.isEmpty()) {
            result.success = false;
            result.errorMessage = 'No creatable fields.';
            return result;
        }

        Database.SaveResult sr = Database.insert(stripped[0], false);
        
        if (sr.isSuccess()) {
            result.success = true;
            result.recordId = sr.getId();
        } else {
            result.success = false;
            if (!sr.getErrors().isEmpty()) {
                result.errorMessage = sr.getErrors()[0].getMessage();
            }
        }
        
        return result;
    }

    // ============================================================
    // Update assignment
    // ============================================================
    @AuraEnabled
    public static SaveResult updateAssignment(
        Id recordId,
        String paNumber,
        Decimal item,
        String nextAction,
        String assignment,
        String actionBy,
        Date targetDate,
        String status,
        Id projectId,
        Integer sortOrder
    ) {
        SaveResult result = new SaveResult();
        
        if (recordId == null) {
            result.success = false;
            result.errorMessage = 'Record ID is required.';
            return result;
        }

        Project_Assignment__c rec = new Project_Assignment__c(
            Id = recordId,
            Name = paNumber,
            Item__c = item,
            Next_Action_Decision_Required__c = nextAction,
            Assignment_Description__c = assignment,
            Action_By2__c = actionBy,
            Target_Status__c = targetDate,
            Priority_Notes__c = status,
            Project__c = projectId,
            Sort_Order__c = sortOrder
        );

        SObjectAccessDecision sd = Security.stripInaccessible(
            AccessType.UPDATABLE, 
            new List<Project_Assignment__c>{ rec }
        );
        List<SObject> stripped = sd.getRecords();
        
        if (stripped.isEmpty()) {
            result.success = false;
            result.errorMessage = 'No updatable fields.';
            return result;
        }

        Database.SaveResult sr = Database.update(stripped[0], false);
        result.recordId = recordId;
        
        if (sr.isSuccess()) {
            result.success = true;
        } else {
            result.success = false;
            if (!sr.getErrors().isEmpty()) {
                result.errorMessage = sr.getErrors()[0].getMessage();
            }
        }
        
        return result;
    }

    // ============================================================
    // Delete assignment
    // ============================================================
    @AuraEnabled
    public static SaveResult deleteAssignment(Id recordId) {
        SaveResult result = new SaveResult();
        
        if (recordId == null) {
            result.success = false;
            result.errorMessage = 'Record ID is required.';
            return result;
        }

        Database.DeleteResult dr = Database.delete(recordId, false);
        result.recordId = recordId;
        
        if (dr.isSuccess()) {
            result.success = true;
        } else {
            result.success = false;
            if (!dr.getErrors().isEmpty()) {
                result.errorMessage = dr.getErrors()[0].getMessage();
            }
        }
        
        return result;
    }

    // ============================================================
    // Bulk update item numbers (for renumbering after reorder/delete)
    // ============================================================
    @AuraEnabled
    public static SaveResult bulkUpdateItemNumbers(String updatesJson) {
        SaveResult result = new SaveResult();
        
        try {
            System.debug('Received updatesJson: ' + updatesJson);
            
            // Deserialize as a generic object first
            Object deserializedObj = JSON.deserializeUntyped(updatesJson);
            
            // Cast to List<Object>
            List<Object> updatesList = (List<Object>) deserializedObj;
            
            List<Project_Assignment__c> toUpdate = new List<Project_Assignment__c>();
            
            // Iterate through the list
            for (Object obj : updatesList) {
                // Cast each item to Map<String, Object>
                Map<String, Object> upd = (Map<String, Object>) obj;
                
                Id recordId = (Id) upd.get('id');
                Object itemObj = upd.get('item');
                Object sortOrderObj = upd.get('sortOrder');
                
                System.debug('Processing record: ' + recordId + ', item: ' + itemObj + ', sortOrder: ' + sortOrderObj);
                
                Decimal itemValue = null;
                if (itemObj != null) {
                    itemValue = Decimal.valueOf(String.valueOf(itemObj));
                }
                
                Integer sortOrderValue = null;
                if (sortOrderObj != null) {
                    sortOrderValue = Integer.valueOf(sortOrderObj);
                }
                
                Project_Assignment__c rec = new Project_Assignment__c(
                    Id = recordId,
                    Item__c = itemValue,
                    Sort_Order__c = sortOrderValue
                );
                toUpdate.add(rec);
            }
            
            System.debug('Total records to update: ' + toUpdate.size());
            
            if (!toUpdate.isEmpty()) {
                SObjectAccessDecision sd = Security.stripInaccessible(
                    AccessType.UPDATABLE, 
                    toUpdate
                );
                List<SObject> stripped = sd.getRecords();
                
                System.debug('Records after stripInaccessible: ' + stripped.size());
                
                // Actually check the results of the update
                Database.SaveResult[] saveResults = Database.update(stripped, false);
                
                // Check for errors
                List<String> errors = new List<String>();
                Integer successCount = 0;
                for (Database.SaveResult sr : saveResults) {
                    if (sr.isSuccess()) {
                        successCount++;
                        System.debug('Successfully updated: ' + sr.getId());
                    } else {
                        for (Database.Error err : sr.getErrors()) {
                            String errorMsg = err.getMessage();
                            errors.add(errorMsg);
                            System.debug('Error updating record: ' + errorMsg);
                        }
                    }
                }
                
                System.debug('Update complete: ' + successCount + ' success, ' + errors.size() + ' errors');
                
                if (!errors.isEmpty()) {
                    result.success = false;
                    result.errorMessage = 'Update failed: ' + String.join(errors, '; ');
                    return result;
                }
            }
            
            result.success = true;
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            System.debug('Error in bulkUpdateItemNumbers: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
        
        return result;
    }

    // ============================================================
    // Delete ContentDocument (for file deletion)
    // ============================================================
    @AuraEnabled
    public static SaveResult deleteContentDocument(Id contentDocumentId) {
        SaveResult result = new SaveResult();
        
        if (contentDocumentId == null) {
            result.success = false;
            result.errorMessage = 'Content Document ID is required.';
            return result;
        }

        try {
            Database.DeleteResult dr = Database.delete(contentDocumentId, false);
            result.recordId = contentDocumentId;
            
            if (dr.isSuccess()) {
                result.success = true;
            } else {
                result.success = false;
                if (!dr.getErrors().isEmpty()) {
                    result.errorMessage = dr.getErrors()[0].getMessage();
                }
            }
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            System.debug('Error deleting ContentDocument: ' + e.getMessage());
        }
        
        return result;
    }

    // ============================================================
    // Helpers
    // ============================================================
    private static String normalizeTerm(String s) {
        if (String.isBlank(s)) return '';
        s = s.trim();
        s = s.replace('\\', '\\\\');
        s = s.replace('%', '\\%');
        s = s.replace('_', '\\_');
        return s;
    }

    private static List<LookupOption> toOptions(List<SObject> recs) {
        List<LookupOption> out = new List<LookupOption>();
        if (recs == null) return out;

        for (SObject s : recs) {
            out.add(new LookupOption((Id)s.get('Id'), (String)s.get('Name')));
        }
        return out;
    }
}