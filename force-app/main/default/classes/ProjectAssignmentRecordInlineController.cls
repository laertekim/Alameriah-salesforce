public with sharing class ProjectAssignmentRecordInlineController {

    // ============================================================
    // DTOs
    // ============================================================
    public class RowInput {
        @AuraEnabled public String paNumber;
        @AuraEnabled public Long item;
        @AuraEnabled public String nextAction;
        @AuraEnabled public String assignment;
        @AuraEnabled public Date targetDate;
        @AuraEnabled public String status;
        @AuraEnabled public Id project;
        @AuraEnabled public Id executiveReport;
    }

    public class RowResult {
        @AuraEnabled public Integer rowIndex;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String recordId;
        @AuraEnabled public List<String> errors = new List<String>();
    }

    // Generic combobox Option
    public class LookupOption {
        @AuraEnabled public Id value;
        @AuraEnabled public String label;

        public LookupOption(Id value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    public class AssignmentResultRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String paNumber;
        @AuraEnabled public Long item;
        @AuraEnabled public String nextAction;
        @AuraEnabled public String assignment;
        @AuraEnabled public Date targetDate;
        @AuraEnabled public String status;
        @AuraEnabled public String projectName;
    }

    public class ActionResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Id recordId;
    }

    // ============================================================
    // Picklist Priority_Notes__c (Status)
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
    // Searches (Typeahead)
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

    @AuraEnabled(cacheable=true)
    public static List<AssignmentResultRow> searchAssignmentsByProjectName(String searchTerm) {
        return searchAssignmentsByProjectNameInternal(searchTerm);
    }

    @AuraEnabled(cacheable=true)
    public static List<AssignmentResultRow> searchAssignmentsByProjectNameWithNonce(String searchTerm, Integer cacheBuster) {
        return searchAssignmentsByProjectNameInternal(searchTerm);
    }

    private static List<AssignmentResultRow> searchAssignmentsByProjectNameInternal(String searchTerm) {
        String term = normalizeTerm(searchTerm);
        if (String.isBlank(term)) return new List<AssignmentResultRow>();

        String searchPattern = '%' + term + '%';
        List<Project_Assignment__c> recs = [
            SELECT Id,
                   Name,
                   Item__c,
                   Next_Action_Decision_Required__c,
                   Assignment_Description__c,
                   Target_Status__c,
                   Priority_Notes__c,
                   Project__r.Name
            FROM Project_Assignment__c
            WHERE Project__r.Name LIKE :searchPattern
            ORDER BY Project__r.Name, Name
            LIMIT 50
        ];

        SObjectAccessDecision sd = Security.stripInaccessible(AccessType.READABLE, recs);
        List<SObject> stripped = sd.getRecords();

        List<AssignmentResultRow> out = new List<AssignmentResultRow>();
        for (SObject s : stripped) {
            Project_Assignment__c rec = (Project_Assignment__c) s;
            AssignmentResultRow row = new AssignmentResultRow();
            row.id = rec.Id;
            row.paNumber = rec.Name;
            row.item = rec.Item__c != null ? rec.Item__c.longValue() : null;
            row.nextAction = rec.Next_Action_Decision_Required__c;
            row.assignment = rec.Assignment_Description__c;
            row.targetDate = rec.Target_Status__c;
            row.status = rec.Priority_Notes__c;
            row.projectName = rec.Project__r != null ? rec.Project__r.Name : null;
            out.add(row);
        }

        return out;
    }

    @AuraEnabled
    public static ActionResult updateAssignmentRow(
        Id recordId,
        String paNumber,
        Long item,
        String nextAction,
        String assignment,
        Date targetDate,
        String status
    ) {
        ActionResult result = new ActionResult();
        if (recordId == null) {
            result.success = false;
            result.errorMessage = 'Missing record id.';
            return result;
        }

        Project_Assignment__c rec = new Project_Assignment__c(
            Id = recordId,
            Name = paNumber,
            Item__c = item,
            Next_Action_Decision_Required__c = nextAction,
            Assignment_Description__c = assignment,
            Target_Status__c = targetDate,
            Priority_Notes__c = status
        );

        SObjectAccessDecision sd = Security.stripInaccessible(AccessType.UPDATABLE, new List<Project_Assignment__c>{ rec });
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

    @AuraEnabled
    public static ActionResult deleteAssignmentRow(Id recordId) {
        ActionResult result = new ActionResult();
        if (recordId == null) {
            result.success = false;
            result.errorMessage = 'Missing record id.';
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

    @AuraEnabled(cacheable=true)
    public static List<LookupOption> searchExecutiveReports(String searchTerm) {
        String term = normalizeTerm(searchTerm);

        List<Executive_Report__c> recs;
        if (String.isBlank(term)) {
            recs = [
                SELECT Id, Name
                FROM Executive_Report__c
                ORDER BY Name
                LIMIT 50
            ];
        } else {
            String searchPattern = '%' + term + '%';
            recs = [
                SELECT Id, Name
                FROM Executive_Report__c
                WHERE Name LIKE :searchPattern
                ORDER BY Name
                LIMIT 50
            ];
        }
        return toOptions(recs);
    }

    // ============================================================
    // Solve label by Id (to fill combobox when Id exists)
    // ============================================================
    @AuraEnabled(cacheable=true)
    public static List<LookupOption> resolveProjectsByIds(List<Id> ids) {
        if (ids == null || ids.isEmpty()) return new List<LookupOption>();
        List<Project__c> recs = [
            SELECT Id, Name
            FROM Project__c
            WHERE Id IN :ids
            LIMIT 200
        ];
        return toOptions(recs);
    }

    @AuraEnabled(cacheable=true)
    public static List<LookupOption> resolveExecutiveReportsByIds(List<Id> ids) {
        if (ids == null || ids.isEmpty()) return new List<LookupOption>();
        List<Executive_Report__c> recs = [
            SELECT Id, Name
            FROM Executive_Report__c
            WHERE Id IN :ids
            LIMIT 200
        ];
        return toOptions(recs);
    }

    // ============================================================
    // Get Next PA Number
    // ============================================================
    @AuraEnabled
    public static String getNextPANumber() {
        // Busca o último PA Number que segue o padrão "PA #00000X"
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
            // Extrai o número do padrão "PA #00000X"
            // Remove "PA #" e tenta extrair o número
            String numberPart = lastPAName.replace('PA #', '').trim();
            try {
                Integer lastNumber = Integer.valueOf(numberPart);
                nextNumber = lastNumber + 1;
            } catch (Exception e) {
                // Se não conseguir converter, começa do 1
                nextNumber = 1;
            }
        }

        // Formata como "PA #00000X" com padding de zeros (5 dígitos)
        String numberStr = String.valueOf(nextNumber);
        while (numberStr.length() < 5) {
            numberStr = '0' + numberStr;
        }
        return 'PA #' + numberStr;
    }

    @AuraEnabled
    public static List<RowResult> saveRows(Id executeReportID, String rowsJson) {

        if (executeReportID == null) {
            throw new AuraHandledException('Missing report id (Executive_Report__c).');
        }
        if (String.isBlank(rowsJson)) {
            return new List<RowResult>();
        }

        // Manually deserialize
        List<RowInput> rows = (List<RowInput>) JSON.deserialize(rowsJson, List<RowInput>.class);

        System.debug('ExecuteReportID: ' + executeReportID);
        System.debug('Rows deserialized size: ' + rows.size());
        System.debug('Rows deserialized sample: ' + JSON.serializePretty(rows.size() > 0 ? rows[0] : null));

        List<Project_Assignment__c> linesToInsert = new List<Project_Assignment__c>();
        List<Integer> indexMap = new List<Integer>();

        for (Integer i = 0; i < rows.size(); i++) {
            RowInput row = rows[i];

            Boolean allFieldsBlank =
                String.isBlank(row.paNumber) &&
                row.item == null &&
                String.isBlank(row.nextAction) &&
                String.isBlank(row.assignment) &&
                row.targetDate == null &&
                String.isBlank(row.status) &&
                row.project == null &&
                row.executiveReport == null;

            if (allFieldsBlank) continue;

            Project_Assignment__c rec = new Project_Assignment__c();
            rec.Executive_Report__c = (row.executiveReport != null) ? row.executiveReport : executeReportID;

            rec.Name = row.paNumber;
            rec.Item__c = row.item;
            rec.Next_Action_Decision_Required__c = row.nextAction;
            rec.Assignment_Description__c = row.assignment;
            rec.Target_Status__c = row.targetDate;
            rec.Priority_Notes__c = row.status;
            rec.Project__c = row.project;

            linesToInsert.add(rec);
            indexMap.add(i);
        }

        SObjectAccessDecision sd = Security.stripInaccessible(AccessType.CREATABLE, linesToInsert);
        List<SObject> stripped = sd.getRecords();

        List<RowResult> results = new List<RowResult>();
        Database.SaveResult[] srList = Database.insert(stripped, false);

        for (Integer j = 0; j < srList.size(); j++) {
            Integer originalIndex = indexMap[j];
            RowResult rr = new RowResult();
            rr.rowIndex = originalIndex;

            if (srList[j].isSuccess()) {
                rr.success = true;
                rr.recordId = srList[j].getId();
            } else {
                rr.success = false;
                for (Database.Error e : srList[j].getErrors()) {
                    rr.errors.add(e.getMessage());
                }
            }
            results.add(rr);
        }

        return results;
    }

    // ============================================================
    // Helpers
    // ============================================================
    private static String normalizeTerm(String s) {
        if (String.isBlank(s)) return '';
        s = s.trim();
        // escape de LIKE (%, _, \) usando ESCAPE '\'
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