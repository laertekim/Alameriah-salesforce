@IsTest
public class ExecRepAssignmentsLwcControllerTest {
    @testSetup
    static void setupData() {
        Executive_Report__c previousReport = new Executive_Report__c(
            Week_Start_Date__c = Date.today().toStartOfWeek().addDays(-7)
        );
        insert previousReport;

        Project__c seedProject = createProject('Seed Project');
        createAssignment(previousReport.Id, seedProject.Id);
    }

    private static Executive_Report__c createExecutiveReport() {
        Executive_Report__c report = new Executive_Report__c();
        insert report;
        return report;
    }

    private static Project__c createProject(String name) {
        Project__c project = new Project__c(
            Name = name
        );
        insert project;
        return project;
    }

    private static Project_Assignment__c createAssignment(Id reportId, Id projectId) {
        Project_Assignment__c assignment = new Project_Assignment__c(
            Executive_Report__c = reportId,
            Project__c = projectId,
            Item__c = 1,
            Assignment_Description__c = 'Test description',
            Next_Action_Decision_Required__c = 'Next action',
            Action_By2__c = 'John Doe',
            Target_Status__c = Date.today(),
            Priority_Notes__c = 'In Progress'
        );
        insert assignment;
        return assignment;
    }

    @IsTest
    static void testGetAssignments() {
        Executive_Report__c report = createExecutiveReport();
        Project__c project = createProject('Project A');
        createAssignment(report.Id, project.Id);

        Test.startTest();
        List<Project_Assignment__c> results =
            ExecutiveReportAssignmentsLwcController.getAssignments(report.Id);
        Test.stopTest();

        Project_Assignment__c match;
        for (Project_Assignment__c row : results) {
            if (row.Project__r != null && row.Project__r.Name == 'Project A') {
                match = row;
                break;
            }
        }

        System.assertNotEquals(null, match, 'Should include Project A');
        System.assertEquals(Date.today(), match.Target_Status__c, 'Target status');
    }

    @IsTest
    static void testSavePdfFromLwc() {
        Executive_Report__c report = createExecutiveReport();
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('PDF'));
        String fileName = 'Report.pdf';

        Test.startTest();
        Id contentVersionId =
            ExecutiveReportAssignmentsLwcController.savePdfFromLwc(report.Id, base64Data, fileName);
        Test.stopTest();

        ContentVersion cv = [
            SELECT Id, Title, PathOnClient, FirstPublishLocationId
            FROM ContentVersion
            WHERE Id = :contentVersionId
        ];

        System.assertEquals('Report', cv.Title, 'File title');
        System.assertEquals('Report.pdf', cv.PathOnClient, 'File name');
        System.assertEquals(report.Id, cv.FirstPublishLocationId, 'Publish location');
    }

    @IsTest
    static void testSavePdfFromLwc_UsesDefaultFileName() {
        Executive_Report__c report = createExecutiveReport();
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('PDF'));

        Test.startTest();
        Id contentVersionId =
            ExecutiveReportAssignmentsLwcController.savePdfFromLwc(report.Id, base64Data, null);
        Test.stopTest();

        ContentVersion cv = [
            SELECT Id, Title, PathOnClient
            FROM ContentVersion
            WHERE Id = :contentVersionId
        ];

        System.assertNotEquals(null, cv.Title, 'Title should not be null');
        System.assertEquals(true, cv.PathOnClient.endsWith('.pdf'), 'Must end with .pdf');
    }

    @IsTest
    static void testSavePdfFromLwc_AppendsPdfExtension() {
        Executive_Report__c report = createExecutiveReport();
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('PDF'));

        Test.startTest();
        Id contentVersionId =
            ExecutiveReportAssignmentsLwcController.savePdfFromLwc(report.Id, base64Data, 'FileWithoutExtension');
        Test.stopTest();

        ContentVersion cv = [
            SELECT Id, PathOnClient
            FROM ContentVersion
            WHERE Id = :contentVersionId
        ];

        System.assertEquals('FileWithoutExtension.pdf', cv.PathOnClient, 'Appends .pdf extension');
    }
}