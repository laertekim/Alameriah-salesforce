import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchAssignmentsByProjectNameWithNonce from '@salesforce/apex/ProjectAssignmentRecordInlineController.searchAssignmentsByProjectNameWithNonce';
import getStatusPicklistValues from '@salesforce/apex/ProjectAssignmentRecordInlineController.getStatusPicklistValues';
import updateAssignmentRow from '@salesforce/apex/ProjectAssignmentRecordInlineController.updateAssignmentRow';
import deleteAssignmentRow from '@salesforce/apex/ProjectAssignmentRecordInlineController.deleteAssignmentRow';

export default class ProjectAssignmentSearchResults extends LightningElement {
    @track results = [];
    @track isLoading = false;
    @track statusOptions = [];

    _searchTerm = '';
    _debounceTimer = null;
    _lastRequestedTerm = '';
    _refreshKey = 0;

    @api
    get searchTerm() {
        return this._searchTerm;
    }
    set searchTerm(value) {
        const term = value || '';
        if (term === this._searchTerm) return;
        this._searchTerm = term;
        this._queueSearch(term);
    }

    @api
    get refreshKey() {
        return this._refreshKey;
    }
    set refreshKey(value) {
        if (value === this._refreshKey) return;
        this._refreshKey = value;
        if (this._searchTerm && this._searchTerm.length >= 2) {
            this._queueSearch(this._searchTerm);
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
    }

    _queueSearch(term) {
        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }

        if (!term || term.length < 2) {
            this._clearResults();
            return;
        }

        this._debounceTimer = setTimeout(() => {
            this._runSearch(term);
        }, 350);
    }

    async _runSearch(term) {
        this.isLoading = true;
        this._lastRequestedTerm = term;
        try {
            const results = await searchAssignmentsByProjectNameWithNonce({
                searchTerm: term,
                cacheBuster: this._refreshKey
            });
            if (this._lastRequestedTerm !== term) return;
            this.results = (results || []).map(r => ({
                id: r.id,
                paNumber: r.paNumber,
                item: r.item,
                nextActionText: this._stripHtml(r.nextAction),
                assignmentText: this._stripHtml(r.assignment),
                targetDate: r.targetDate,
                status: r.status,
                projectName: r.projectName,
                isSaving: false,
                isDeleting: false,
                isDirty: false
            }));
        } catch (e) {
            if (this._lastRequestedTerm === term) {
                this.results = [];
            }
            // keep console logging minimal; errors are non-blocking for UX
            // eslint-disable-next-line no-console
            console.error('Error searching project assignments:', e);
        } finally {
            if (this._lastRequestedTerm === term) {
                this.isLoading = false;
            }
        }
    }

    _clearResults() {
        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }
        this._lastRequestedTerm = '';
        this.results = [];
        this.isLoading = false;
    }

    get showSection() {
        return this._searchTerm && this._searchTerm.length >= 2;
    }

    get showNoResults() {
        return this.showSection && !this.isLoading && this.results.length === 0;
    }

    handleFieldChange(event) {
        const rowId = event.target?.dataset?.rowId;
        const field = event.target?.dataset?.field;
        if (!rowId || !field) return;

        let value = event.detail?.value;
        if (value === undefined) value = event.target?.value;

        const updated = this.results.map(row => {
            if (row.id !== rowId) return row;
            return { ...row, [field]: value, isDirty: true };
        });
        this.results = updated;
    }

    async handleSaveRow(event) {
        const rowId = event.currentTarget?.dataset?.rowId;
        if (!rowId) return;

        const row = this.results.find(r => r.id === rowId);
        if (!row) return;

        this._setRowState(rowId, { isSaving: true });
        try {
            const result = await updateAssignmentRow({
                recordId: rowId,
                paNumber: row.paNumber,
                item: row.item !== '' && row.item != null ? Number(row.item) : null,
                nextAction: row.nextActionText,
                assignment: row.assignmentText,
                targetDate: row.targetDate || null,
                status: row.status
            });

            if (result?.success) {
                this._setRowState(rowId, { isSaving: false, isDirty: false });
                this._toast('Success', 'Record updated successfully.', 'success');
            } else {
                this._setRowState(rowId, { isSaving: false });
                this._toast('Error', result?.errorMessage || 'Error updating assignment.', 'error');
            }
        } catch (e) {
            this._setRowState(rowId, { isSaving: false });
            this._toast('Error', 'Error updating assignment.', 'error');
            // eslint-disable-next-line no-console
            console.error('Error updating assignment:', e);
        }
    }

    async handleDeleteRow(event) {
        const rowId = event.currentTarget?.dataset?.rowId;
        if (!rowId) return;

        this._setRowState(rowId, { isDeleting: true });
        try {
            const result = await deleteAssignmentRow({ recordId: rowId });
            if (result?.success) {
                this.results = this.results.filter(r => r.id !== rowId);
                this._toast('Success', 'Record deleted.', 'success');
            } else {
                this._setRowState(rowId, { isDeleting: false });
                this._toast('Error', result?.errorMessage || 'Falha ao excluir.', 'error');
            }
        } catch (e) {
            this._setRowState(rowId, { isDeleting: false });
            this._toast('Error', 'Falha ao excluir.', 'error');
            // eslint-disable-next-line no-console
            console.error('Error deleting assignment:', e);
        }
    }

    _setRowState(rowId, patch) {
        this.results = this.results.map(row => {
            if (row.id !== rowId) return row;
            return { ...row, ...patch };
        });
    }

    _toast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    _stripHtml(value) {
        if (!value) return '';
        const container = document.createElement('div');
        container.innerHTML = value;
        return (container.textContent || container.innerText || '').trim();
    }
}