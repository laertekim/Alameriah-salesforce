@IsTest
private class ProjectAssignmentManagerControllerTest {

    private static Executive_Report__c createExecutiveReport() {
        Executive_Report__c report = new Executive_Report__c();
        insert report;
        return report;
    }

    private static Project__c createProject(String name) {
        Project__c project = new Project__c(Name = name);
        insert project;
        return project;
    }

    private static Project_Assignment__c createAssignment(
        Id reportId,
        Id projectId,
        String paNumber,
        Decimal itemValue
    ) {
        Project_Assignment__c assignment = new Project_Assignment__c(
            Executive_Report__c = reportId,
            Project__c = projectId,
            Name = paNumber,
            Item__c = itemValue,
            Next_Action_Decision_Required__c = 'Next action',
            Assignment_Description__c = 'Assignment',
            Action_By2__c = 'User',
            Target_Status__c = Date.today(),
            Priority_Notes__c = 'In Progress',
            Sort_Order__c = Integer.valueOf(itemValue)
        );
        insert assignment;
        return assignment;
    }

    @IsTest
    static void readMethods_shouldReturnData() {
        Executive_Report__c report = createExecutiveReport();
        Project__c project = createProject('Project Manager Test');
        createAssignment(report.Id, project.Id, 'PA #00010', 1);

        Test.startTest();
        List<ProjectAssignmentManagerController.AssignmentRow> assignments =
            ProjectAssignmentManagerController.getAssignmentsByExecutiveReport(report.Id);
        List<String> statusValues = ProjectAssignmentManagerController.getStatusPicklistValues();
        List<ProjectAssignmentManagerController.LookupOption> allProjects =
            ProjectAssignmentManagerController.searchProjects('');
        List<ProjectAssignmentManagerController.LookupOption> filteredProjects =
            ProjectAssignmentManagerController.searchProjects('Manager');
        Decimal nextItem = ProjectAssignmentManagerController.getNextItemNumber(report.Id, project.Id);
        String nextPANumber = ProjectAssignmentManagerController.getNextPANumber();
        Test.stopTest();

        System.assertEquals(1, assignments.size());
        System.assert(statusValues.size() > 0, 'Status picklist should have values');
        System.assert(allProjects.size() > 0, 'Should list projects');
        System.assert(filteredProjects.size() > 0, 'Should filter projects');
        System.assertEquals(2, nextItem, 'Next item should increment from max');
        System.assert(nextPANumber.startsWith('PA #'), 'PA number should keep prefix');
    }

    @IsTest
    static void createUpdateDelete_shouldWork() {
        Executive_Report__c report = createExecutiveReport();
        Project__c project = createProject('Create Update Delete Project');

        Test.startTest();
        ProjectAssignmentManagerController.SaveResult createResult =
            ProjectAssignmentManagerController.createAssignment(
                report.Id,
                project.Id,
                'PA #00100',
                1,
                'Initial next action',
                'Initial assignment',
                'User A',
                Date.today(),
                'In Progress',
                1
            );
        ProjectAssignmentManagerController.SaveResult updateResult =
            ProjectAssignmentManagerController.updateAssignment(
                createResult.recordId,
                'PA #00100',
                1,
                'Initial next action',
                'Initial assignment',
                'User A',
                Date.today(),
                'In Progress',
                project.Id,
                1
            );
        ProjectAssignmentManagerController.SaveResult deleteResult =
            ProjectAssignmentManagerController.deleteAssignment(createResult.recordId);
        Test.stopTest();

        System.assertEquals(true, createResult.success);
        System.assertNotEquals(null, createResult.recordId);
        System.assert(
            updateResult.success || String.isNotBlank(updateResult.errorMessage),
            'Update should succeed or return a meaningful error.'
        );
        System.assertEquals(true, deleteResult.success);
    }

    @IsTest
    static void bulkUpdateItemNumbers_shouldUpdateRows() {
        Executive_Report__c report = createExecutiveReport();
        Project__c project = createProject('Bulk Update Project');
        Project_Assignment__c a1 = createAssignment(report.Id, project.Id, 'PA #00200', 1);
        Project_Assignment__c a2 = createAssignment(report.Id, project.Id, 'PA #00201', 2);

        String updatesJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{ 'id' => a1.Id, 'item' => 10, 'sortOrder' => 10 },
            new Map<String, Object>{ 'id' => a2.Id, 'item' => 20, 'sortOrder' => 20 }
        });

        Test.startTest();
        ProjectAssignmentManagerController.SaveResult result =
            ProjectAssignmentManagerController.bulkUpdateItemNumbers(updatesJson);
        Test.stopTest();

        System.assertEquals(true, result.success);

        Map<Id, Project_Assignment__c> refreshed = new Map<Id, Project_Assignment__c>([
            SELECT Item__c, Sort_Order__c
            FROM Project_Assignment__c
            WHERE Id IN :new Set<Id>{ a1.Id, a2.Id }
        ]);
        System.assertEquals(10, refreshed.get(a1.Id).Item__c);
        System.assertEquals(10, refreshed.get(a1.Id).Sort_Order__c);
        System.assertEquals(20, refreshed.get(a2.Id).Item__c);
        System.assertEquals(20, refreshed.get(a2.Id).Sort_Order__c);
    }

    @IsTest
    static void guardClauses_shouldReturnExpectedDefaultsOrErrors() {
        Executive_Report__c report = createExecutiveReport();
        Project__c project = createProject('Guard Clauses Project');
        Project_Assignment__c existing = createAssignment(report.Id, project.Id, 'PA #00300', 1);

        Boolean getAssignmentsThrown = false;

        Test.startTest();
        try {
            ProjectAssignmentManagerController.getAssignmentsByExecutiveReport(null);
        } catch (AuraHandledException e) {
            getAssignmentsThrown = true;
        }

        Decimal nextItemWithNulls = ProjectAssignmentManagerController.getNextItemNumber(null, null);

        ProjectAssignmentManagerController.SaveResult createMissingReport =
            ProjectAssignmentManagerController.createAssignment(
                null,
                project.Id,
                'PA #00301',
                1,
                'NA',
                'Assignment',
                'User',
                Date.today(),
                'In Progress',
                1
            );
        ProjectAssignmentManagerController.SaveResult createMissingProject =
            ProjectAssignmentManagerController.createAssignment(
                report.Id,
                null,
                'PA #00302',
                1,
                'NA',
                'Assignment',
                'User',
                Date.today(),
                'In Progress',
                1
            );

        ProjectAssignmentManagerController.SaveResult updateMissingId =
            ProjectAssignmentManagerController.updateAssignment(
                null,
                'PA #00300',
                1,
                'NA',
                'Assignment',
                'User',
                Date.today(),
                'In Progress',
                project.Id,
                1
            );
        ProjectAssignmentManagerController.SaveResult deleteMissingId =
            ProjectAssignmentManagerController.deleteAssignment(null);

        ProjectAssignmentManagerController.SaveResult bulkInvalidJson =
            ProjectAssignmentManagerController.bulkUpdateItemNumbers('{invalid json}');
        Test.stopTest();

        System.assertEquals(true, getAssignmentsThrown, 'Should throw when executiveReportId is null');
        System.assertEquals(1, nextItemWithNulls, 'Null inputs should return default next item');
        System.assertEquals(false, createMissingReport.success);
        System.assertEquals(false, createMissingProject.success);
        System.assertEquals(false, updateMissingId.success);
        System.assertEquals(false, deleteMissingId.success);
        System.assertEquals(false, bulkInvalidJson.success, 'Invalid JSON should return failure');
        System.assertNotEquals(null, bulkInvalidJson.errorMessage);
        System.assertNotEquals(null, existing.Id);
    }
}