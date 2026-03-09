@IsTest
private class ProjectAssignmentRecordInlineControllerTest {

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

    private static Project_Assignment__c createAssignment(Id reportId, Id projectId, String paNumber) {
        Project_Assignment__c rec = new Project_Assignment__c(
            Executive_Report__c = reportId,
            Project__c = projectId,
            Name = paNumber,
            Item__c = 1,
            Next_Action_Decision_Required__c = 'Next action',
            Assignment_Description__c = 'Assignment',
            Action_By2__c = 'User',
            Target_Status__c = Date.today(),
            Priority_Notes__c = 'In Progress'
        );
        insert rec;
        return rec;
    }

    @IsTest
    static void searchAndResolveMethods_shouldReturnData() {
        Executive_Report__c report = createExecutiveReport();
        Project__c project = createProject('Inline Project');
        createAssignment(report.Id, project.Id, 'PA #00050');

        Test.startTest();
        List<String> statuses = ProjectAssignmentRecordInlineController.getStatusPicklistValues();
        List<ProjectAssignmentRecordInlineController.LookupOption> projects =
            ProjectAssignmentRecordInlineController.searchProjects('Inline');
        List<ProjectAssignmentRecordInlineController.LookupOption> reports =
            ProjectAssignmentRecordInlineController.searchExecutiveReports('');
        List<ProjectAssignmentRecordInlineController.AssignmentResultRow> assignments =
            ProjectAssignmentRecordInlineController.searchAssignmentsByProjectName('Inline');
        List<ProjectAssignmentRecordInlineController.AssignmentResultRow> assignmentsWithNonce =
            ProjectAssignmentRecordInlineController.searchAssignmentsByProjectNameWithNonce('Inline', 1);
        List<ProjectAssignmentRecordInlineController.LookupOption> resolvedProjects =
            ProjectAssignmentRecordInlineController.resolveProjectsByIds(new List<Id>{ project.Id });
        List<ProjectAssignmentRecordInlineController.LookupOption> resolvedReports =
            ProjectAssignmentRecordInlineController.resolveExecutiveReportsByIds(new List<Id>{ report.Id });
        String nextPA = ProjectAssignmentRecordInlineController.getNextPANumber();
        Test.stopTest();

        System.assert(statuses.size() > 0, 'Status list should not be empty');
        System.assert(projects.size() > 0, 'Project search should return data');
        System.assert(reports.size() > 0, 'Executive report search should return data');
        System.assert(assignments.size() > 0, 'Assignment search should return data');
        System.assert(assignmentsWithNonce.size() > 0, 'Assignment search with nonce should return data');
        System.assertEquals(1, resolvedProjects.size(), 'Should resolve project by id');
        System.assertEquals(1, resolvedReports.size(), 'Should resolve report by id');
        System.assert(nextPA.startsWith('PA #'), 'PA format should be preserved');
    }

    @IsTest
    static void saveRows_shouldInsertOneRow() {
        Executive_Report__c report = createExecutiveReport();
        Project__c project = createProject('Inline SaveRows Project');

        String rowsJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'paNumber' => 'PA #00999',
                'item' => 1,
                'nextAction' => 'Do action',
                'assignment' => 'Assignment text',
                'actionBy' => 'User',
                'targetDate' => Date.today(),
                'status' => 'In Progress',
                'project' => project.Id,
                'executiveReport' => report.Id
            }
        });

        Test.startTest();
        List<ProjectAssignmentRecordInlineController.RowResult> results =
            ProjectAssignmentRecordInlineController.saveRows(report.Id, rowsJson);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'One row result expected');
        System.assertEquals(true, results[0].success, 'Insert should succeed');
        System.assertNotEquals(null, results[0].recordId, 'Record id should be returned');
    }

    @IsTest
    static void updateAndDelete_shouldWork_andNullGuardsShouldReturnError() {
        Executive_Report__c report = createExecutiveReport();
        Project__c project = createProject('Inline Update Project');
        Project_Assignment__c rec = createAssignment(report.Id, project.Id, 'PA #00123');

        Test.startTest();
        ProjectAssignmentRecordInlineController.ActionResult updateOk =
            ProjectAssignmentRecordInlineController.updateAssignmentRow(
                rec.Id,
                'PA #00123',
                2,
                'Updated action',
                'Updated assignment',
                'Another User',
                Date.today().addDays(1),
                'Completed'
            );
        ProjectAssignmentRecordInlineController.ActionResult updateFail =
            ProjectAssignmentRecordInlineController.updateAssignmentRow(
                null, null, null, null, null, null, null, null
            );
        ProjectAssignmentRecordInlineController.ActionResult deleteOk =
            ProjectAssignmentRecordInlineController.deleteAssignmentRow(rec.Id);
        ProjectAssignmentRecordInlineController.ActionResult deleteFail =
            ProjectAssignmentRecordInlineController.deleteAssignmentRow(null);
        Test.stopTest();

        System.assertEquals(true, updateOk.success, 'Update should succeed');
        System.assertEquals(false, updateFail.success, 'Null guard must fail');
        System.assertEquals(true, deleteOk.success, 'Delete should succeed');
        System.assertEquals(false, deleteFail.success, 'Null guard must fail');
    }
}
