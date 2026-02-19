import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getAssignmentsByExecutiveReport from '@salesforce/apex/ProjectAssignmentManagerController.getAssignmentsByExecutiveReport';
import getStatusPicklistValues from '@salesforce/apex/ProjectAssignmentManagerController.getStatusPicklistValues';
import searchProjects from '@salesforce/apex/ProjectAssignmentManagerController.searchProjects';
import getNextItemNumber from '@salesforce/apex/ProjectAssignmentManagerController.getNextItemNumber';
import getNextPANumber from '@salesforce/apex/ProjectAssignmentManagerController.getNextPANumber';
import createAssignment from '@salesforce/apex/ProjectAssignmentManagerController.createAssignment';
import updateAssignment from '@salesforce/apex/ProjectAssignmentManagerController.updateAssignment';
import deleteAssignment from '@salesforce/apex/ProjectAssignmentManagerController.deleteAssignment';
import bulkUpdateItemNumbers from '@salesforce/apex/ProjectAssignmentManagerController.bulkUpdateItemNumbers';
import deleteContentDocument from '@salesforce/apex/ProjectAssignmentManagerController.deleteContentDocument';

export default class ProjectAssignmentManager extends LightningElement {
    @api recordId;
    
    // Using individual @track for better reactivity
    @track assignments = [];
    @track projectOptions = [];
    @track statusOptions = [];
    @track isLoading = true;
    @track errorMessage = null;
    @track debugInfo = '';
    
    // Modal state
    @track isModalOpen = false;
    @track isSavingModal = false;
    @track newRow = {};
    
    // Upload modal state
    @track isUploadModalOpen = false;
    @track uploadRecordId = null;
    
    // Manage files modal state
    @track isManageFilesModalOpen = false;
    @track currentFiles = [];
    @track manageFilesRecordId = null;

    draggedRowId = null;
    draggedOverRowId = null;
    _dataLoaded = false;
    _renderCount = 0;
    _resizeInitialized = false;
    _autoSaveTimers = {}; // Store debounce timers per row
    _projectColors = {}; // Store project ID to color mapping

    // Filter state
    @track filters = {
        projectId: '',
        nextAction: '',
        assignment: '',
        actionBy: '',
        targetDateFrom: '',
        targetDateTo: '',
        status: ''
    };

    @track projectFilterOptions = [];
    @track statusFilterOptions = [];
    @track projectLegend = []; // For displaying the color legend

    connectedCallback() {
        console.log('=== COMPONENT CONNECTED ===');
        console.log('recordId in connectedCallback:', this.recordId);
        console.log('isLoading:', this.isLoading);
        
        this.debugInfo = 'Connected - recordId: ' + this.recordId;
        
        this.loadProjects();
        this.loadStatusOptions();
        
        // Try to extract recordId from URL if not provided
        if (!this.recordId) {
            this.recordId = this.extractRecordIdFromUrl();
            console.log('Extracted recordId from URL:', this.recordId);
        }
        
        if (this.recordId) {
            console.log('recordId available, loading data...');
            this.loadData();
        } else {
            this.isLoading = false;
            this.errorMessage = 'No Executive Report ID found';
            console.error('No recordId available');
        }
    }

    renderedCallback() {
        this._renderCount++;
        console.log(`=== RENDERED (count: ${this._renderCount}) ===`);
        console.log('isLoading:', this.isLoading);
        console.log('assignments.length:', this.assignments.length);
        console.log('errorMessage:', this.errorMessage);
        
        // Check badges in DOM
        const badges = this.template.querySelectorAll('.attachment-badge');
        console.log('Attachment badges in DOM:', badges.length);
        badges.forEach((badge, idx) => {
            console.log(`  Badge ${idx}: style="${badge.style.cssText}"`);
        });
        
        // Apply colors to legend items
        this.applyLegendColors();
        
        // Apply colors to table rows
        this.applyRowColors();
        
        // Initialize column resizing (only once)
        if (!this._resizeInitialized) {
            this.initColumnResize();
            this._resizeInitialized = true;
        }
        
        // Load data when recordId becomes available (fallback)
        if (this.recordId && !this._dataLoaded && this._renderCount < 5) {
            console.log('Attempting to load data from renderedCallback...');
            this._dataLoaded = true;
            this.loadData();
        }
    }

    // ============================================================
    // Filter Methods
    // ============================================================
    handleFilterChange(event) {
        const filterName = event.currentTarget.dataset.filter;
        const value = event.detail.value;
        
        console.log(`Filter changed: ${filterName} = ${value}`);
        
        this.filters = {
            ...this.filters,
            [filterName]: value
        };
    }

    clearFilters() {
        console.log('=== CLEAR FILTERS ===');
        this.filters = {
            projectId: '',
            nextAction: '',
            assignment: '',
            actionBy: '',
            targetDateFrom: '',
            targetDateTo: '',
            status: ''
        };
    }

    populateFilterOptions() {
        // Populate project filter options
        const uniqueProjects = new Set();
        this.assignments.forEach(row => {
            if (row.projectId && row.projectName) {
                uniqueProjects.add(JSON.stringify({ value: row.projectId, label: row.projectName }));
            }
        });
        
        this.projectFilterOptions = [
            { label: 'All Projects', value: '' },
            ...Array.from(uniqueProjects).map(p => JSON.parse(p))
        ];

        // Populate status filter options
        this.statusFilterOptions = [
            { label: 'All Statuses', value: '' },
            ...this.statusOptions
        ];
    }

    // ============================================================
    // Column Resize Functionality
    // ============================================================
    initColumnResize() {
        const handles = this.template.querySelectorAll('.resize-handle');
        handles.forEach(handle => {
            handle.addEventListener('mousedown', this.handleResizeStart.bind(this));
        });
    }

    handleResizeStart(event) {
        event.preventDefault();
        const columnClass = event.target.dataset.column;
        const th = event.target.parentElement;
        
        const startX = event.pageX;
        const startWidth = th.offsetWidth;

        const handleMouseMove = (e) => {
            const diff = e.pageX - startX;
            const newWidth = Math.max(50, startWidth + diff);
            
            // Update width using CSS
            const styleElement = this.getOrCreateStyleElement();
            const rule = `.${columnClass} { width: ${newWidth}px !important; }`;
            
            // Find and update or add rule
            let found = false;
            for (let i = styleElement.sheet.cssRules.length - 1; i >= 0; i--) {
                if (styleElement.sheet.cssRules[i].selectorText === `.${columnClass}`) {
                    styleElement.sheet.deleteRule(i);
                    found = true;
                    break;
                }
            }
            styleElement.sheet.insertRule(rule, styleElement.sheet.cssRules.length);
        };

        const handleMouseUp = () => {
            document.removeEventListener('mousemove', handleMouseMove);
            document.removeEventListener('mouseup', handleMouseUp);
        };

        document.addEventListener('mousemove', handleMouseMove);
        document.addEventListener('mouseup', handleMouseUp);
    }

    getOrCreateStyleElement() {
        let styleElement = this.template.querySelector('#dynamic-column-styles');
        if (!styleElement) {
            styleElement = document.createElement('style');
            styleElement.id = 'dynamic-column-styles';
            this.template.querySelector('.table-container').appendChild(styleElement);
        }
        return styleElement;
    }

    // ============================================================
    // Legend Color Application
    // ============================================================
    applyLegendColors() {
        // Use setTimeout to ensure DOM is fully rendered
        setTimeout(() => {
            const colorBoxes = this.template.querySelectorAll('.legend-color-box');
            console.log('=== APPLYING LEGEND COLORS ===');
            console.log('Found', colorBoxes.length, 'color boxes');
            console.log('Project legend has', this.projectLegend.length, 'items');
            
            colorBoxes.forEach((box, index) => {
                const color = box.dataset.color;
                console.log(`Box ${index}: color="${color}"`);
                if (color) {
                    // Apply styles very explicitly
                    box.style.backgroundColor = color;
                    box.style.border = '1px solid #d8dde6';
                    box.style.width = '24px';
                    box.style.height = '24px';
                    box.style.display = 'inline-block';
                    box.style.minWidth = '24px';
                    box.style.minHeight = '24px';
                    console.log(`  Applied color: ${color}`);
                    console.log(`  Computed style:`, window.getComputedStyle(box).backgroundColor);
                }
            });
        }, 100);
    }

    applyRowColors() {
        setTimeout(() => {
            const rows = this.template.querySelectorAll('tbody tr[data-id]');
            console.log('=== APPLYING ROW COLORS ===');
            console.log('Found', rows.length, 'rows');
            
            rows.forEach((row, index) => {
                const rowId = row.dataset.id;
                const assignment = this.assignments.find(a => a.id === rowId);
                if (assignment && assignment.projectId) {
                    const color = this.getProjectColor(assignment.projectId);
                    if (color && color !== 'transparent') {
                        row.style.backgroundColor = color;
                        const computed = window.getComputedStyle(row).backgroundColor;
                        console.log(`Row ${index} (${assignment.projectName}): ${color} => Computed: ${computed}`);
                    }
                }
            });
        }, 100);
    }

    extractRecordIdFromUrl() {
        try {
            const pathname = window.location.pathname;
            console.log('Analyzing pathname:', pathname);
            
            // Pattern: /lightning/r/Executive_Report__c/{recordId}/view
            const match = pathname.match(/\/lightning\/r\/[^\/]+\/([a-zA-Z0-9]{15,18})\//);
            if (match && match[1]) {
                console.log('Found recordId in URL:', match[1]);
                return match[1];
            }
            
            // Alternative pattern
            const altMatch = pathname.match(/\/([a-zA-Z0-9]{15,18})$/);
            if (altMatch && altMatch[1]) {
                console.log('Found recordId (alt pattern):', altMatch[1]);
                return altMatch[1];
            }
            
            console.log('No recordId found in URL');
            return null;
        } catch (error) {
            console.error('Error extracting recordId from URL:', error);
            return null;
        }
    }

    // ============================================================
    // Data Loading
    // ============================================================
    async loadData() {
        console.log('=== LOADDATA CALLED ===');
        console.log('recordId:', this.recordId);
        console.log('isLoading BEFORE:', this.isLoading);
        
        if (!this.recordId) {
            console.error('No recordId - aborting load');
            this.isLoading = false;
            this.errorMessage = 'Executive Report ID not found.';
            this.debugInfo = 'ERROR: No recordId';
            return;
        }

        // Force loading state
        this.isLoading = true;
        this.errorMessage = null;
        this.debugInfo = 'Loading data for: ' + this.recordId;
        
        console.log('isLoading set to TRUE');
        console.log('Calling Apex...');

        try {
            const data = await getAssignmentsByExecutiveReport({ 
                executiveReportId: this.recordId 
            });
            
            console.log('âœ… APEX RETURNED DATA:', data ? data.length : 0, 'records');
            console.log('Full data:', JSON.stringify(data, null, 2));
            
            // Force new array to trigger reactivity
            this.assignments = [];
            
            console.log('Starting to process rows...');
            
            const newAssignments = (data || []).map((row, index) => {
                try {
                    console.log(`Processing row ${index + 1}/${data.length} - ID: ${row.id}:`, row.attachments ? row.attachments.length : 0, 'attachments');
                    
                    // Generate Salesforce preview URLs for attachments
                    const attachmentsWithUrls = (row.attachments || []).map(att => {
                        console.log('  - File:', att.fileName, 'ID:', att.contentDocumentId);
                        return {
                            ...att,
                            fileUrl: `/lightning/r/ContentDocument/${att.contentDocumentId}/view`,
                            fileSizeFormatted: this.formatFileSize(att.fileSize),
                            isDeleting: false
                        };
                    });
                    
                    // Generate attachment tooltip
                    const tooltipText = attachmentsWithUrls.length > 0 ?
                        attachmentsWithUrls.map(a => a.fileName).join('\n') :
                        'No attachments';
                    
                    console.log(`  Has attachments: ${attachmentsWithUrls.length > 0}`);
                    console.log(`  Attachment count: ${attachmentsWithUrls.length}`);
                    console.log(`  Tooltip: ${tooltipText}`);
                    
                    const processedRow = {
                        id: row.id,
                        paNumber: row.paNumber,
                        item: row.item,
                        nextAction: row.nextAction,
                        assignment: row.assignment,
                        actionBy: row.actionBy,
                        targetDate: row.targetDate,
                        status: row.status,
                        projectId: row.projectId,
                        projectName: row.projectName,
                        sortOrder: row.sortOrder,
                        attachments: attachmentsWithUrls,
                        hasAttachments: attachmentsWithUrls.length > 0,
                        attachmentCount: attachmentsWithUrls.length,
                        attachmentTooltip: tooltipText,
                        attachmentBadgeStyle: attachmentsWithUrls.length > 0 ? '' : 'display:none',
                        isNew: false,
                        isSaving: false,
                        isDeleting: false,
                        isDirty: false,
                        rowClass: ''
                    };
                    
                    console.log(`  Badge style: "${processedRow.attachmentBadgeStyle}"`);
                    
                    console.log(`  Processed row hasAttachments: ${processedRow.hasAttachments}`);
                    console.log(`  Processed row attachmentBadgeStyle: "${processedRow.attachmentBadgeStyle}"`);
                    
                    return processedRow;
                } catch (rowError) {
                    console.error(`Error processing row ${index}:`, rowError);
                    console.error('Row data:', row);
                    throw rowError;
                }
            });
            
            console.log('Finished processing. Total rows:', newAssignments.length);
            console.log('Rows with attachments:', newAssignments.filter(r => r.hasAttachments).length);
            
            console.log('Mapped assignments:', newAssignments.length);
            
            // Set assignments
            this.assignments = newAssignments;
            
            console.log('assignments array set, length:', this.assignments.length);
            console.log('First row check:', {
                id: this.assignments[0]?.id,
                hasAttachments: this.assignments[0]?.hasAttachments,
                attachmentCount: this.assignments[0]?.attachmentCount,
                attachmentBadgeStyle: this.assignments[0]?.attachmentBadgeStyle,
                attachments: this.assignments[0]?.attachments
            });
            console.log('Setting isLoading to FALSE...');
            
            // Generate project colors
            this.generateProjectColors();
            
            // Apply colors to rows
            this.assignments = this.assignments.map(row => ({
                ...row,
                backgroundColor: this.getProjectColor(row.projectId),
                rowStyle: `background-color: ${this.getProjectColor(row.projectId)};`
            }));
            
            // Populate filter options after data is loaded
            this.populateFilterOptions();
            
            // Force isLoading to false
            this.isLoading = false;
            
            console.log('isLoading is now:', this.isLoading);
            
            this.debugInfo = `Loaded ${this.assignments.length} assignments`;
            
            // Force a re-render
            this.template.host.setAttribute('data-loaded', 'true');

        } catch (error) {
            this.errorMessage = this.getErrorMessage(error);
            console.error('âŒ ERROR loading data:', error);
            console.error('Error details:', JSON.stringify(error));
            this.showToast('Error', this.errorMessage, 'error');
            this.debugInfo = 'ERROR: ' + this.errorMessage;
        } finally {
            this.isLoading = false;
            console.log('=== LOADDATA COMPLETE ===');
            console.log('FINAL isLoading:', this.isLoading);
            console.log('FINAL assignments.length:', this.assignments.length);
        }
    }

    async loadProjects() {
        try {
            const results = await searchProjects({ searchTerm: '' });
            this.projectOptions = (results || []).map(opt => ({
                label: opt.label,
                value: opt.value
            }));
            console.log('âœ… Loaded projects:', this.projectOptions.length);
        } catch (error) {
            console.error('âŒ Error loading projects:', error);
        }
    }

    async loadStatusOptions() {
        try {
            const values = await getStatusPicklistValues();
            this.statusOptions = (values || []).map(val => ({
                label: val,
                value: val
            }));
            console.log('âœ… Loaded status options:', this.statusOptions.length);
        } catch (error) {
            console.error('âŒ Error loading status options:', error);
        }
    }

    // ============================================================
    // Modal Management
    // ============================================================
    async openModal() {
        console.log('=== OPENING MODAL ===');
        try {
            const nextPANumber = await getNextPANumber();
            
            // Initialize new row data
            this.newRow = {
                paNumber: nextPANumber,
                item: null,
                nextAction: '',
                assignment: '',
                actionBy: '',
                targetDate: null,
                status: '',
                projectId: null
            };
            
            this.isModalOpen = true;
            console.log('Modal opened with PA Number:', nextPANumber);
        } catch (error) {
            console.error('Error opening modal:', error);
            this.showToast('Error', 'Failed to generate PA Number', 'error');
        }
    }

    closeModal() {
        console.log('=== CLOSING MODAL ===');
        this.isModalOpen = false;
        this.isSavingModal = false;
        this.newRow = {};
    }

    async handleModalFieldChange(event) {
        const field = event.currentTarget.dataset.field;
        const value = event.detail.value;
        
        console.log(`Modal field changed: ${field} = ${value}`);
        
        // Update the field
        this.newRow = {
            ...this.newRow,
            [field]: value
        };

        // If project changed, calculate next item number
        if (field === 'projectId' && value) {
            try {
                const nextItem = await getNextItemNumber({
                    executiveReportId: this.recordId,
                    projectId: value
                });
                this.newRow = {
                    ...this.newRow,
                    item: nextItem
                };
                console.log('Auto-calculated item number:', nextItem);
            } catch (error) {
                console.error('Error getting next item number:', error);
            }
        }
    }

    async saveFromModal() {
        console.log('=== SAVING FROM MODAL ===');
        
        // Validation
        if (!this.newRow.projectId) {
            this.showToast('Error', 'Project is required', 'error');
            return;
        }

        this.isSavingModal = true;

        try {
            const result = await createAssignment({
                executiveReportId: this.recordId,
                projectId: this.newRow.projectId,
                paNumber: this.newRow.paNumber,
                item: this.newRow.item,
                nextAction: this.newRow.nextAction,
                assignment: this.newRow.assignment,
                actionBy: this.newRow.actionBy,
                targetDate: this.newRow.targetDate,
                status: this.newRow.status,
                sortOrder: null
            });

            if (result.success) {
                this.showToast('Success', 'Assignment created successfully', 'success');
                console.log('Assignment created with ID:', result.recordId);
                
                // Close modal
                this.closeModal();
                
                // Reload data
                this._dataLoaded = false;
                await this.loadData();
                
            } else {
                this.isSavingModal = false;
                this.showToast('Error', result.errorMessage || 'Failed to save', 'error');
            }
        } catch (error) {
            this.isSavingModal = false;
            this.showToast('Error', this.getErrorMessage(error), 'error');
            console.error('Error saving from modal:', error);
        }
    }

    // ============================================================
    // File Upload Management
    // ============================================================
    handleUploadClick(event) {
        const recordId = event.currentTarget.dataset.id;
        console.log('=== UPLOAD CLICKED FOR RECORD:', recordId);
        
        this.uploadRecordId = recordId;
        this.isUploadModalOpen = true;
    }

    closeUploadModal() {
        console.log('=== CLOSING UPLOAD MODAL ===');
        this.isUploadModalOpen = false;
        this.uploadRecordId = null;
    }

    async handleUploadFinished(event) {
        console.log('=== UPLOAD FINISHED ===');
        const uploadedFiles = event.detail.files;
        console.log('Uploaded files:', uploadedFiles.length);
        
        this.showToast('Success', 
                      `${uploadedFiles.length} file(s) uploaded successfully`, 
                      'success');
        
        // Close modal
        this.closeUploadModal();
        
        // Reload data to show new attachments
        this._dataLoaded = false;
        await this.loadData();
    }

    // ============================================================
    // File Management Methods
    // ============================================================
    handleManageFiles(event) {
        const recordId = event.currentTarget.dataset.id;
        console.log('=== MANAGE FILES FOR RECORD:', recordId);
        
        const row = this.assignments.find(r => r.id === recordId);
        if (!row) return;
        
        this.manageFilesRecordId = recordId;
        this.currentFiles = row.attachments || [];
        this.isManageFilesModalOpen = true;
    }

    closeManageFilesModal() {
        console.log('=== CLOSING MANAGE FILES MODAL ===');
        this.isManageFilesModalOpen = false;
        this.currentFiles = [];
        this.manageFilesRecordId = null;
    }

    handleAddMoreFiles() {
        console.log('=== ADD MORE FILES ===');
        // Close manage modal and open upload modal
        this.isManageFilesModalOpen = false;
        this.uploadRecordId = this.manageFilesRecordId;
        this.isUploadModalOpen = true;
    }

    async handleDeleteFile(event) {
        const contentDocumentId = event.currentTarget.dataset.documentId;
        const fileName = event.currentTarget.dataset.fileName;
        
        console.log('=== DELETE FILE:', fileName, contentDocumentId);
        
        if (!confirm(`Are you sure you want to delete "${fileName}"?`)) {
            return;
        }

        // Set deleting state
        this.currentFiles = this.currentFiles.map(file => {
            if (file.contentDocumentId === contentDocumentId) {
                return { ...file, isDeleting: true };
            }
            return file;
        });

        try {
            // Delete ContentDocument via Apex
            const result = await deleteContentDocument({ 
                contentDocumentId: contentDocumentId 
            });
            
            if (result.success) {
                console.log('File deleted successfully');
                this.showToast('Success', `"${fileName}" deleted successfully`, 'success');
                
                // Remove from current files list
                this.currentFiles = this.currentFiles.filter(f => f.contentDocumentId !== contentDocumentId);
                
                // Reload data
                this._dataLoaded = false;
                await this.loadData();
                
            } else {
                throw new Error(result.errorMessage || 'Failed to delete file');
            }
        } catch (error) {
            console.error('âŒ Error deleting file:', error);
            this.showToast('Error', this.getErrorMessage(error), 'error');
            
            // Reset deleting state
            this.currentFiles = this.currentFiles.map(file => {
                if (file.contentDocumentId === contentDocumentId) {
                    return { ...file, isDeleting: false };
                }
                return file;
            });
        }
    }

    formatFileSize(bytes) {
        if (!bytes || bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
    }

    // ============================================================
    // Add New Row (Legacy - keeping for inline add if needed)
    // ============================================================
    async handleAddRow() {
        console.log('=== ADD ROW CLICKED ===');
        try {
            const nextPANumber = await getNextPANumber();
            
            const newRow = {
                id: this.generateTempId(),
                paNumber: nextPANumber,
                item: null,
                nextAction: '',
                assignment: '',
                actionBy: '',
                targetDate: null,
                status: '',
                projectId: null,
                projectName: null,
                sortOrder: null,
                attachments: [],
                hasAttachments: false,
                attachmentCount: 0,
                attachmentTooltip: 'No attachments',
                attachmentBadgeStyle: 'display:none',
                isNew: true,
                isSaving: false,
                isDeleting: false,
                isDirty: true,
                rowClass: 'new-row',
                backgroundColor: 'transparent',
                rowStyle: ''
            };

            // Force new array
            this.assignments = [...this.assignments, newRow];
            console.log('Row added. Total assignments:', this.assignments.length);
        } catch (error) {
            console.error('Error adding row:', error);
            this.showToast('Error', 'Failed to generate PA Number', 'error');
        }
    }

    // ============================================================
    // Field Change Handling
    // ============================================================
    async handleFieldChange(event) {
        const rowId = event.currentTarget.dataset.id;
        const field = event.currentTarget.dataset.field;
        const value = event.detail.value;

        const rowIndex = this.assignments.findIndex(r => r.id === rowId);
        if (rowIndex === -1) return;

        const updatedAssignments = [...this.assignments];
        const row = { ...updatedAssignments[rowIndex] };
        
        row[field] = value;
        row.isDirty = true;

        // If project changes on a new row, calculate next item number
        if (field === 'projectId' && row.isNew && value) {
            try {
                const nextItem = await getNextItemNumber({
                    executiveReportId: this.recordId,
                    projectId: value
                });
                row.item = nextItem;
                
                // Update project name for display
                const project = this.projectOptions.find(p => p.value === value);
                if (project) {
                    row.projectName = project.label;
                }
                
                // Update row color
                row.backgroundColor = this.getProjectColor(value);
                row.rowStyle = `background-color: ${this.getProjectColor(value)};`;
            } catch (error) {
                console.error('Error getting next item number:', error);
            }
        }

        updatedAssignments[rowIndex] = row;
        this.assignments = updatedAssignments;

        // Auto-save when item number changes (with debouncing)
        if (field === 'item' && !row.isNew) {
            this.debouncedAutoSave(rowId);
        }
    }

    // ============================================================
    // Debounced Auto-Save for Item Number Changes
    // ============================================================
    debouncedAutoSave(rowId) {
        // Clear existing timer for this row
        if (this._autoSaveTimers[rowId]) {
            clearTimeout(this._autoSaveTimers[rowId]);
        }

        // Set new timer (wait 1 second after user stops typing)
        this._autoSaveTimers[rowId] = setTimeout(() => {
            this.autoSaveRow(rowId);
            delete this._autoSaveTimers[rowId];
        }, 1000);
    }

    async autoSaveRow(rowId) {
        const rowIndex = this.assignments.findIndex(r => r.id === rowId);
        if (rowIndex === -1) return;

        const row = this.assignments[rowIndex];

        // Validation
        if (!row.projectId) {
            console.log('Skipping auto-save: Project is required');
            return;
        }

        console.log('=== AUTO-SAVING ROW:', rowId);
        this.setRowState(rowId, { isSaving: true });

        try {
            const result = await updateAssignment({
                recordId: row.id,
                paNumber: row.paNumber,
                item: row.item,
                nextAction: row.nextAction,
                assignment: row.assignment,
                actionBy: row.actionBy,
                targetDate: row.targetDate,
                status: row.status,
                projectId: row.projectId,
                sortOrder: row.sortOrder
            });

            if (result.success) {
                this.setRowState(rowId, { 
                    isSaving: false, 
                    isDirty: false 
                });
                console.log('✅ Auto-save successful');
                // Show subtle success notification
                this.showToast('Saved', 'Changes saved automatically', 'success');
            } else {
                this.setRowState(rowId, { isSaving: false });
                this.showToast('Error', result.errorMessage || 'Auto-save failed', 'error');
            }
        } catch (error) {
            this.setRowState(rowId, { isSaving: false });
            console.error('Auto-save error:', error);
            this.showToast('Error', this.getErrorMessage(error), 'error');
        }
    }

    // ============================================================
    // Save Row
    // ============================================================
    async handleSaveRow(event) {
        const rowId = event.currentTarget.dataset.id;
        const rowIndex = this.assignments.findIndex(r => r.id === rowId);
        if (rowIndex === -1) return;

        const row = this.assignments[rowIndex];

        // Validation
        if (!row.projectId) {
            this.showToast('Error', 'Project is required', 'error');
            return;
        }

        this.setRowState(rowId, { isSaving: true });

        try {
            let result;
            
            if (row.isNew) {
                // Create new assignment
                result = await createAssignment({
                    executiveReportId: this.recordId,
                    projectId: row.projectId,
                    paNumber: row.paNumber,
                    item: row.item,
                    nextAction: row.nextAction,
                    assignment: row.assignment,
                    actionBy: row.actionBy,
                    targetDate: row.targetDate,
                    status: row.status,
                    sortOrder: row.sortOrder
                });
            } else {
                // Update existing assignment
                result = await updateAssignment({
                    recordId: row.id,
                    paNumber: row.paNumber,
                    item: row.item,
                    nextAction: row.nextAction,
                    assignment: row.assignment,
                    actionBy: row.actionBy,
                    targetDate: row.targetDate,
                    status: row.status,
                    projectId: row.projectId,
                    sortOrder: row.sortOrder
                });
            }

            if (result.success) {
                this.showToast('Success', 'Assignment saved successfully', 'success');
                
                if (row.isNew) {
                    // Replace temp ID with real ID
                    const updatedAssignments = [...this.assignments];
                    updatedAssignments[rowIndex] = {
                        ...row,
                        id: result.recordId,
                        isNew: false,
                        isDirty: false,
                        isSaving: false,
                        rowClass: ''
                    };
                    this.assignments = updatedAssignments;
                } else {
                    this.setRowState(rowId, { 
                        isSaving: false, 
                        isDirty: false 
                    });
                }
                
                // Reload to get fresh data
                this._dataLoaded = false;
                await this.loadData();
            } else {
                this.setRowState(rowId, { isSaving: false });
                this.showToast('Error', result.errorMessage || 'Failed to save', 'error');
            }
        } catch (error) {
            this.setRowState(rowId, { isSaving: false });
            this.showToast('Error', this.getErrorMessage(error), 'error');
        }
    }

    // ============================================================
    // Delete Row
    // ============================================================
    async handleDeleteRow(event) {
        const rowId = event.currentTarget.dataset.id;
        const rowIndex = this.assignments.findIndex(r => r.id === rowId);
        if (rowIndex === -1) return;

        const row = this.assignments[rowIndex];

        // If it's a new row (not saved yet), just remove it
        if (row.isNew) {
            this.assignments = this.assignments.filter(r => r.id !== rowId);
            return;
        }

        if (!confirm('Are you sure you want to delete this assignment?')) {
            return;
        }

        this.setRowState(rowId, { isDeleting: true });

        try {
            const result = await deleteAssignment({ recordId: rowId });

            if (result.success) {
                this.showToast('Success', 'Assignment deleted successfully', 'success');
                
                // Remove from list
                const projectId = row.projectId;
                this.assignments = this.assignments.filter(r => r.id !== rowId);
                
                // Renumber items for the same project
                await this.renumberProjectItems(projectId);
                
            } else {
                this.setRowState(rowId, { isDeleting: false });
                this.showToast('Error', result.errorMessage || 'Failed to delete', 'error');
            }
        } catch (error) {
            this.setRowState(rowId, { isDeleting: false });
            this.showToast('Error', this.getErrorMessage(error), 'error');
        }
    }

    // ============================================================
    // Drag and Drop
    // ============================================================
    handleDragStart(event) {
        this.draggedRowId = event.currentTarget.dataset.id;
        event.currentTarget.classList.add('dragging');
    }

    handleDragOver(event) {
        event.preventDefault();
        const rowId = event.currentTarget.dataset.id;
        
        if (rowId !== this.draggedRowId) {
            this.draggedOverRowId = rowId;
            event.currentTarget.classList.add('drag-over');
        }
    }

    handleDrop(event) {
        event.preventDefault();
        event.stopPropagation();
        
        const dropTargetId = event.currentTarget.dataset.id;
        event.currentTarget.classList.remove('drag-over');

        if (this.draggedRowId && dropTargetId && this.draggedRowId !== dropTargetId) {
            this.reorderRows(this.draggedRowId, dropTargetId);
        }
    }

    handleDragEnd(event) {
        event.currentTarget.classList.remove('dragging');
        
        // Remove all drag-over classes
        const rows = this.template.querySelectorAll('tr[draggable="true"]');
        rows.forEach(row => row.classList.remove('drag-over'));
        
        this.draggedRowId = null;
        this.draggedOverRowId = null;
    }

    async reorderRows(draggedId, targetId) {
        const draggedIndex = this.assignments.findIndex(r => r.id === draggedId);
        const targetIndex = this.assignments.findIndex(r => r.id === targetId);

        if (draggedIndex === -1 || targetIndex === -1) return;

        const draggedRow = this.assignments[draggedIndex];
        const targetRow = this.assignments[targetIndex];

        // Only allow reordering within the same project
        if (draggedRow.projectId !== targetRow.projectId) {
            this.showToast('Warning', 
                'Can only reorder items within the same project', 
                'warning');
            return;
        }

        // Reorder the array
        const reordered = [...this.assignments];
        const [removed] = reordered.splice(draggedIndex, 1);
        reordered.splice(targetIndex, 0, removed);
        this.assignments = reordered;

        // Renumber items for this project and save automatically
        await this.renumberProjectItems(draggedRow.projectId, true);
    }

    // ============================================================
    // Helper: Renumber Project Items
    // ============================================================
    async renumberProjectItems(projectId, showFeedback = false) {
        if (!projectId) return;

        console.log('=== RENUMBER PROJECT ITEMS ===');
        console.log('Project ID:', projectId);
        console.log('Show feedback:', showFeedback);

        const projectRows = this.assignments
            .filter(r => r.projectId === projectId && !r.isNew)
            .sort((a, b) => {
                const aIndex = this.assignments.findIndex(row => row.id === a.id);
                const bIndex = this.assignments.findIndex(row => row.id === b.id);
                return aIndex - bIndex;
            });

        console.log('Found', projectRows.length, 'rows to renumber');

        if (projectRows.length === 0) return;

        // Update item numbers locally
        const updates = [];
        const updatedAssignments = [...this.assignments];

        projectRows.forEach((row, index) => {
            const newItemNumber = index + 1;
            const rowIndex = updatedAssignments.findIndex(r => r.id === row.id);
            
            console.log(`  Row ${index}: ID=${row.id}, Old Item=${row.item}, New Item=${newItemNumber}`);
            
            if (rowIndex !== -1) {
                updatedAssignments[rowIndex] = {
                    ...updatedAssignments[rowIndex],
                    item: newItemNumber,
                    sortOrder: index
                };
                
                updates.push({
                    id: row.id,
                    item: newItemNumber,
                    sortOrder: index
                });
            }
        });

        this.assignments = updatedAssignments;

        // Save to server
        if (updates.length > 0) {
            console.log('Sending updates to server:', JSON.stringify(updates, null, 2));
            
            try {
                const result = await bulkUpdateItemNumbers({ 
                    updatesJson: JSON.stringify(updates) 
                });
                
                console.log('Server response:', result);
                
                if (result && result.success) {
                    if (showFeedback) {
                        console.log('✅ Order saved successfully');
                        this.showToast('Saved', 'Item order saved automatically', 'success');
                    }
                } else {
                    console.error('❌ Bulk update failed:', result ? result.errorMessage : 'Unknown error');
                    if (showFeedback) {
                        this.showToast('Error', result.errorMessage || 'Failed to save order changes', 'error');
                    }
                }
            } catch (error) {
                console.error('Error updating item numbers:', error);
                console.error('Error details:', JSON.stringify(error));
                if (showFeedback) {
                    this.showToast('Error', this.getErrorMessage(error), 'error');
                }
            }
        } else {
            console.log('No updates to send');
        }
    }

    // ============================================================
    // Helpers
    // ============================================================
    setRowState(rowId, state) {
        const updatedAssignments = this.assignments.map(row => {
            if (row.id === rowId) {
                return { ...row, ...state };
            }
            return row;
        });
        this.assignments = updatedAssignments;
    }

    generateTempId() {
        return 'temp_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }

    getErrorMessage(error) {
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        return 'An unexpected error occurred';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get showEmptyState() {
        return !this.isLoading && this.filteredAssignments.length === 0;
    }

    get filteredAssignments() {
        if (!this.assignments || this.assignments.length === 0) {
            return [];
        }

        return this.assignments.filter(row => {
            // Project filter
            if (this.filters.projectId && row.projectId !== this.filters.projectId) {
                return false;
            }

            // Next Action filter (case-insensitive contains)
            if (this.filters.nextAction) {
                const nextAction = (row.nextAction || '').toLowerCase();
                const searchTerm = this.filters.nextAction.toLowerCase();
                if (!nextAction.includes(searchTerm)) {
                    return false;
                }
            }

            // Assignment filter (case-insensitive contains)
            if (this.filters.assignment) {
                const assignment = (row.assignment || '').toLowerCase();
                const searchTerm = this.filters.assignment.toLowerCase();
                if (!assignment.includes(searchTerm)) {
                    return false;
                }
            }

            // Action By filter (case-insensitive contains)
            if (this.filters.actionBy) {
                const actionBy = (row.actionBy || '').toLowerCase();
                const searchTerm = this.filters.actionBy.toLowerCase();
                if (!actionBy.includes(searchTerm)) {
                    return false;
                }
            }

            // Target Date From filter
            if (this.filters.targetDateFrom && row.targetDate) {
                if (row.targetDate < this.filters.targetDateFrom) {
                    return false;
                }
            }

            // Target Date To filter
            if (this.filters.targetDateTo && row.targetDate) {
                if (row.targetDate > this.filters.targetDateTo) {
                    return false;
                }
            }

            // Status filter
            if (this.filters.status && row.status !== this.filters.status) {
                return false;
            }

            return true;
        });
    }

    get filteredCount() {
        return this.filteredAssignments.length;
    }

    get totalCount() {
        return this.assignments ? this.assignments.length : 0;
    }

    // ============================================================
    // Project Color Management
    // ============================================================
    generateProjectColors() {
        // Professional, subtle color palette for row backgrounds
        const colorPalette = [
            '#E3F2FD', // Light Blue
            '#F3E5F5', // Light Purple
            '#E8F5E9', // Light Green
            '#FFF3E0', // Light Orange
            '#FCE4EC', // Light Pink
            '#E0F2F1', // Light Teal
            '#FFF9C4', // Light Yellow
            '#F1F8E9', // Light Lime
            '#E1F5FE', // Lighter Blue
            '#F9FBE7', // Pale Yellow-Green
            '#EDE7F6', // Pale Purple
            '#FFEBEE'  // Pale Red
        ];

        // Get unique projects from assignments
        const uniqueProjects = new Set();
        this.assignments.forEach(row => {
            if (row.projectId && row.projectName) {
                uniqueProjects.add(JSON.stringify({
                    id: row.projectId,
                    name: row.projectName
                }));
            }
        });

        const projects = Array.from(uniqueProjects).map(p => JSON.parse(p));

        // Sort projects by name for consistent color assignment
        projects.sort((a, b) => a.name.localeCompare(b.name));

        // Assign colors
        this._projectColors = {};
        const legend = [];

        projects.forEach((project, index) => {
            const color = colorPalette[index % colorPalette.length];
            this._projectColors[project.id] = color;
            legend.push({
                id: project.id,
                name: project.name,
                color: color,
                colorBoxStyle: `background-color: ${color}; border: 1px solid #d8dde6;`
            });
        });

        this.projectLegend = legend;
        console.log('=== PROJECT COLORS GENERATED ===');
        console.log('Number of projects:', legend.length);
        console.log('Project colors map:', this._projectColors);
        console.log('Legend items:', JSON.stringify(legend, null, 2));
    }

    getProjectColor(projectId) {
        return this._projectColors[projectId] || 'transparent';
    }

    get hasProjects() {
        return this.projectLegend && this.projectLegend.length > 0;
    }
}