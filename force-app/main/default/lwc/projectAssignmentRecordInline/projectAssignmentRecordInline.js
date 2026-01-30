import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getStatusPicklistValues from '@salesforce/apex/ProjectAssignmentRecordInlineController.getStatusPicklistValues';
import saveRows from '@salesforce/apex/ProjectAssignmentRecordInlineController.saveRows';
import getNextPANumber from '@salesforce/apex/ProjectAssignmentRecordInlineController.getNextPANumber';

import searchProjects from '@salesforce/apex/ProjectAssignmentRecordInlineController.searchProjects';
import searchExecutiveReports from '@salesforce/apex/ProjectAssignmentRecordInlineController.searchExecutiveReports';
import resolveExecutiveReportsByIds from '@salesforce/apex/ProjectAssignmentRecordInlineController.resolveExecutiveReportsByIds';

export default class ProjectAssignmentRecordInline extends LightningElement {
    @api recordId;

    @track rows = [];
    @track statusOptions = [];
    @track errorBanner = null;

    // Global lookup fields
    @track globalExecutiveReportId = null;
    @track globalExecutiveReportLabel = null;
    @track globalExecutiveReportSearch = '';
    @track globalExecutiveReportOptions = [];
    @track showGlobalExecutiveReportDropdown = false;

    @track globalProjectId = null;
    @track globalProjectLabel = null;
    @track globalProjectSearch = '';
    @track globalProjectOptions = [];
    @track showGlobalProjectDropdown = false;
    @track projectResultsSearchTerm = '';
    @track projectResultsRefreshKey = 0;

    _projectTimers = new Map();
    _execTimers = new Map();
    _globalProjectTimer = null;
    _globalExecTimer = null;

    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        if (!pageRef) return;

        if (!this.recordId) {
            const rid =
                pageRef.attributes?.recordId ||
                pageRef.state?.recordId ||
                pageRef.state?.c__recordId;

            if (rid) {
                this.recordId = rid;
                this.globalExecutiveReportId = rid;
                this._hydrateExecutiveReportLabelToRows();
                this._hydrateGlobalExecutiveReportLabel();
            }
        }
    }

    connectedCallback() {
        getStatusPicklistValues()
            .then(values => {
                this.statusOptions = (values || []).map(v => ({ label: v, value: v }));
            })
            .catch(() => {
                this.statusOptions = [];
            });

        this._hydrateExecutiveReportLabelToRows();

        if (this.recordId) {
            this.globalExecutiveReportId = this.recordId;
            this._hydrateGlobalExecutiveReportLabel();
        }

        // Close Status dropdown when clicking outside
        this._handleDocClick = (e) => {
            // only act when click is in this component DOM
            if (!this.template.contains(e.target)) return;

            const insideStatus = e.target.closest && e.target.closest('.status-combobox');
            if (!insideStatus) {
                this.rows = this.rows.map(r => ({
                    ...r,
                    showStatusDropdown: false,
                    statusComboboxClass: 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click'
                }));
            }
        };
        document.addEventListener('click', this._handleDocClick);

        if (!this.rows || this.rows.length === 0) {
            this.addRow();
        }
    }

    disconnectedCallback() {
        if (this._handleDocClick) {
            document.removeEventListener('click', this._handleDocClick);
        }
    }

    async _hydrateGlobalExecutiveReportLabel() {
        if (!this.globalExecutiveReportId) return;
        try {
            const opts = await resolveExecutiveReportsByIds({ ids: [this.globalExecutiveReportId] });
            this.globalExecutiveReportLabel = (opts && opts.length) ? opts[0].label : null;
        } catch (e) {
            console.error('Error hydrating global executive report label:', e);
        }
    }

    // ----------------------------
    // Helpers
    // ----------------------------
    _uuid() {
        return crypto.randomUUID();
    }

    async _hydrateExecutiveReportLabelToRows() {
        if (!this.recordId) return;

        try {
            const opts = await resolveExecutiveReportsByIds({ ids: [this.recordId] });
            const label = (opts && opts.length) ? opts[0].label : null;
            if (!label) return;

            const copy = [...this.rows];
            let changed = false;

            copy.forEach((r, idx) => {
                if (r.executiveReportId === this.recordId && !r.executiveReportLabel) {
                    copy[idx] = { ...r, executiveReportLabel: label };
                    changed = true;
                }
            });

            if (changed) this.rows = copy;
        } catch (e) {
            // ignore
        }
    }

    async addRow() {
        try {
            const nextPANumber = await getNextPANumber();
            const numberPart = nextPANumber.replace('PA #', '').trim();
            const itemNumber = parseInt(numberPart, 10) || 1;

            this.rows = [
                ...this.rows,
                {
                    key: this._uuid(),

                    paNumber: nextPANumber,
                    item: itemNumber,

                    executiveReportId: null,
                    executiveReportLabel: null,
                    executiveReportSearch: '',
                    executiveReportOptions: [],
                    showExecutiveReportDropdown: false,

                    projectId: null,
                    projectLabel: null,
                    projectSearch: '',
                    projectOptions: [],
                    showProjectDropdown: false,

                    nextAction: '',
                    assignment: '',
                    targetDate: null,

                    // Status custom combobox
                    status: '',
                    statusLabel: '',
                    showStatusDropdown: false,
                    statusComboboxClass: 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click',

                    error: null,
                    errorKey: this._uuid()
                }
            ];
        } catch (error) {
            console.error('Error getting next PA Number:', error);

            this.rows = [
                ...this.rows,
                {
                    key: this._uuid(),
                    paNumber: '',
                    item: null,

                    executiveReportId: null,
                    executiveReportLabel: null,
                    executiveReportSearch: '',
                    executiveReportOptions: [],
                    showExecutiveReportDropdown: false,

                    projectId: null,
                    projectLabel: null,
                    projectSearch: '',
                    projectOptions: [],
                    showProjectDropdown: false,

                    nextAction: '',
                    assignment: '',
                    targetDate: null,

                    status: '',
                    statusLabel: '',
                    showStatusDropdown: false,
                    statusComboboxClass: 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click',

                    error: null,
                    errorKey: this._uuid()
                }
            ];
        }
    }

    removeRow(event) {
        const index = Number(event.target.dataset.index);
        this.rows = this.rows.filter((row, i) => i !== index);
    }

    handleRowEdit(event) {
        const index = Number(event.target.dataset.index);

        if (index === undefined || isNaN(index) || !this.rows[index]) return;

        const copy = [...this.rows];
        copy[index] = { ...copy[index], error: null, errorKey: this._uuid() };
        this.rows = copy;
    }

    handleChange(event) {
        const index = Number(event.target.dataset.index);
        const field = event.target.dataset.field;

        let value = event.detail?.value;
        if (value === undefined) value = event.target?.value;

        if (index === undefined || isNaN(index) || !this.rows[index]) return;

        const copy = [...this.rows];
        const updatedRow = { ...copy[index] };
        updatedRow[field] = value;
        updatedRow.error = null;
        updatedRow.errorKey = this._uuid();
        copy[index] = updatedRow;
        this.rows = copy;
    }

    // ----------------------------
    // Status (custom dropdown)
    // ----------------------------
    toggleStatusDropdown(event) {
        const index = Number(event.currentTarget.dataset.index);
        if (isNaN(index) || !this.rows[index]) return;

        const copy = this.rows.map((r, i) => {
            const willOpen = i === index ? !r.showStatusDropdown : false;
            return {
                ...r,
                showStatusDropdown: willOpen,
                statusComboboxClass: willOpen
                    ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open'
                    : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click'
            };
        });

        this.rows = copy;
    }

    selectStatus(event) {
        const index = Number(event.currentTarget.dataset.index);
        const value = event.currentTarget.dataset.value;
        const label = event.currentTarget.dataset.label;

        if (isNaN(index) || !this.rows[index]) return;

        const copy = [...this.rows];
        copy[index] = {
            ...copy[index],
            status: value,
            statusLabel: label,
            showStatusDropdown: false,
            statusComboboxClass: 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click',
            error: null,
            errorKey: this._uuid()
        };
        this.rows = copy;
    }

    // ----------------------------
    // Global Lookups
    // ----------------------------
    handleGlobalExecutiveReportSearch(event) {
        const term = event.detail?.value ?? event.target?.value ?? '';
        this.globalExecutiveReportSearch = term;
        this.showGlobalExecutiveReportDropdown = false;

        if (this._globalExecTimer) clearTimeout(this._globalExecTimer);

        if (term.length < 2) {
            this.globalExecutiveReportOptions = [];
            this.showGlobalExecutiveReportDropdown = false;
            return;
        }

        this._globalExecTimer = setTimeout(async () => {
            try {
                const options = await searchExecutiveReports({ searchTerm: term });
                this.globalExecutiveReportOptions = (options || []).map(o => ({ label: o.label, value: o.value }));
                this.showGlobalExecutiveReportDropdown = this.globalExecutiveReportOptions.length > 0;
            } catch (e) {
                console.error('Error searching executive reports:', e);
                this.globalExecutiveReportOptions = [];
                this.showGlobalExecutiveReportDropdown = false;
            }
        }, 350);
    }

    async handleGlobalExecutiveReportSelect(event) {
        let target = event.target;
        while (target && !target.dataset.value) {
            target = target.parentElement;
            if (!target) break;
        }

        const selectedId = target?.dataset?.value || null;
        if (!selectedId) return;

        const selectedLabel = this.globalExecutiveReportOptions.find(o => o.value === selectedId)?.label || null;

        this.globalExecutiveReportId = selectedId;
        this.globalExecutiveReportLabel = selectedLabel;
        this.globalExecutiveReportSearch = '';
        this.globalExecutiveReportOptions = [];
        this.showGlobalExecutiveReportDropdown = false;

        try {
            const options = await resolveExecutiveReportsByIds({ ids: [selectedId] });
            if (options && options.length > 0) {
                this.globalExecutiveReportId = options[0].value;
                this.globalExecutiveReportLabel = options[0].label;
            }
        } catch (error) {
            console.error('Error validating global Executive Report ID:', error);
        }
    }

    handleGlobalExecutiveReportClear() {
        this.globalExecutiveReportId = null;
        this.globalExecutiveReportLabel = null;
        this.globalExecutiveReportSearch = '';
        this.globalExecutiveReportOptions = [];
        this.showGlobalExecutiveReportDropdown = false;
    }

    handleGlobalProjectSearch(event) {
        const term = event.detail?.value ?? event.target?.value ?? '';
        this.globalProjectSearch = term;
        this.showGlobalProjectDropdown = false;
        this.projectResultsSearchTerm = term;

        if (this._globalProjectTimer) clearTimeout(this._globalProjectTimer);

        if (term.length < 2) {
            this.globalProjectOptions = [];
            this.showGlobalProjectDropdown = false;
            return;
        }

        this._globalProjectTimer = setTimeout(async () => {
            try {
                const options = await searchProjects({ searchTerm: term });
                this.globalProjectOptions = (options || []).map(o => ({ label: o.label, value: o.value }));
                this.showGlobalProjectDropdown = this.globalProjectOptions.length > 0;
            } catch (e) {
                console.error('Error searching projects:', e);
                this.globalProjectOptions = [];
                this.showGlobalProjectDropdown = false;
            }
        }, 350);
    }

    handleGlobalProjectSelect(event) {
        let target = event.target;
        while (target && !target.dataset.value) {
            target = target.parentElement;
            if (!target) break;
        }

        const selectedId = target?.dataset?.value || null;
        if (!selectedId) return;

        const selectedLabel = this.globalProjectOptions.find(o => o.value === selectedId)?.label || null;

        this.globalProjectId = selectedId;
        this.globalProjectLabel = selectedLabel;
        this.globalProjectSearch = '';
        this.globalProjectOptions = [];
        this.showGlobalProjectDropdown = false;
    }

    handleGlobalProjectClear() {
        this.globalProjectId = null;
        this.globalProjectLabel = null;
        this.globalProjectSearch = '';
        this.globalProjectOptions = [];
        this.showGlobalProjectDropdown = false;
        this.projectResultsSearchTerm = '';
    }

    // ----------------------------
    // Clear Form
    // ----------------------------
    clearForm() {
        this.rows = [];

        this.globalProjectId = null;
        this.globalProjectLabel = null;
        this.globalProjectSearch = '';
        this.globalProjectOptions = [];
        this.showGlobalProjectDropdown = false;
        this.projectResultsSearchTerm = '';

        if (!this.recordId) {
            this.globalExecutiveReportId = null;
            this.globalExecutiveReportLabel = null;
            this.globalExecutiveReportSearch = '';
            this.globalExecutiveReportOptions = [];
            this.showGlobalExecutiveReportDropdown = false;
        } else {
            this.globalExecutiveReportId = this.recordId;
            this._hydrateGlobalExecutiveReportLabel();
        }

        this.errorBanner = null;
    }

    // ----------------------------
    // Save
    // ----------------------------
    async save(event) {
        this.errorBanner = null;

        const indexRaw = event?.currentTarget?.dataset?.index ?? event?.target?.dataset?.index;
        const index = Number(indexRaw);
        const hasIndex = !isNaN(index) && this.rows && this.rows[index];

        const rowsToSave = hasIndex ? [this.rows[index]] : (this.rows || []);
        const rowIndexMap = hasIndex ? [index] : (this.rows || []).map((_, i) => i);

        if (!rowsToSave || rowsToSave.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No data',
                    message: 'Please add at least one row before saving.',
                    variant: 'warning'
                })
            );
            return;
        }

        let executiveReportId = this.globalExecutiveReportId || this.recordId;

        if (!executiveReportId && rowsToSave.length > 0) {
            const firstRowWithReport = rowsToSave.find(row => row.executiveReportId);
            if (firstRowWithReport) {
                executiveReportId = firstRowWithReport.executiveReportId;
            }
        }

        if (!executiveReportId) {
            const pathMatch = window.location.pathname.match(/\/lightning\/r\/([^\/]+)/);
            if (pathMatch) {
                executiveReportId = pathMatch[1];
            } else {
                const urlParams = new URLSearchParams(window.location.search);
                executiveReportId = urlParams.get('id') || urlParams.get('c__recordId');
            }
        }

        if (!executiveReportId) {
            this.errorBanner =
                'Executive Report ID is missing. Please ensure this component is used on an Executive Report record page, or select an Executive Report in at least one row.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.errorBanner,
                    variant: 'error'
                })
            );
            return;
        }

        if (rowIndexMap.length > 0) {
            const cleared = [...this.rows];
            rowIndexMap.forEach(i => {
                if (cleared[i]) {
                    cleared[i] = { ...cleared[i], error: null, errorKey: this._uuid() };
                }
            });
            this.rows = cleared;
        }

        try {
            const payload = rowsToSave.map(row => {
                return {
                    paNumber: (row.paNumber != null && row.paNumber !== '') ? String(row.paNumber).trim() : null,
                    item: (row.item != null && row.item !== '' && !isNaN(row.item)) ? Number(row.item) : null,
                    nextAction: (row.nextAction != null && row.nextAction !== '') ? String(row.nextAction).trim() : null,
                    assignment: (row.assignment != null && row.assignment !== '') ? String(row.assignment).trim() : null,
                    targetDate: (row.targetDate != null && row.targetDate !== '') ? String(row.targetDate) : null,
                    status: (row.status != null && row.status !== '') ? String(row.status) : null,
                    project: (row.projectId != null && row.projectId !== '') ? String(row.projectId) : (this.globalProjectId ? String(this.globalProjectId) : null),
                    executiveReport: (row.executiveReportId != null && row.executiveReportId !== '') ? String(row.executiveReportId) : (this.globalExecutiveReportId ? String(this.globalExecutiveReportId) : null)
                };
            });

            const results = await saveRows({
                executeReportID: executiveReportId,
                rowsJson: JSON.stringify(payload)
            });

            const copy = [...this.rows];
            let successCount = 0;
            let errorCount = 0;

            (results || []).forEach(result => {
                const targetIndex = rowIndexMap[result.rowIndex];
                if (targetIndex === undefined || !copy[targetIndex]) return;

                if (result.success) {
                    successCount++;
                    copy[targetIndex] = { ...copy[targetIndex], error: null };
                } else {
                    errorCount++;
                    const msg = (result.errors || []).join(' | ') || 'Unknown error';
                    copy[targetIndex] = { ...copy[targetIndex], error: msg, errorKey: this._uuid() };
                }
            });

            let nextRows = copy;

            if (!hasIndex && successCount > 0 && errorCount === 0) {
                this.clearForm();
                nextRows = null;
            }

            if (nextRows) {
                this.rows = nextRows;
            }

            if (successCount > 0) {
                this.projectResultsRefreshKey += 1;
            }

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Save complete',
                    message: `Inserted: ${successCount}, Errors: ${errorCount}`,
                    variant: errorCount > 0 ? 'warning' : 'success'
                })
            );
        } catch (error) {
            const errorMessage = error?.body?.message || error?.message || 'Unexpected error while saving.';
            this.errorBanner = errorMessage;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: errorMessage,
                    variant: 'error'
                })
            );
        }
    }
}