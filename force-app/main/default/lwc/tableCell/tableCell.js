import { LightningElement, api } from 'lwc';

export default class TableCell extends LightningElement {
    @api record;
    @api column;
    @api columnIndex;

    get isText() {
        return this.column && (this.column.type === 'text' || !this.column.type);
    }

    get isNumber() {
        return this.column && this.column.type === 'number';
    }

    get isCurrency() {
        return this.column && this.column.type === 'currency';
    }

    get textValue() {
        return this.getFieldValue();
    }

    get numberValue() {
        const val = this.getFieldValue();
        return val ? parseFloat(val) : 0;
    }

    get currencyValue() {
        const val = this.getFieldValue();
        return val ? parseFloat(val) : 0;
    }

    getFieldValue() {
        if (!this.record || !this.column || !this.column.fieldApiName) {
            return '';
        }

        const fieldApiName = this.column.fieldApiName;
        
        // Handle relationship fields (e.g., Building__r.Name)
        if (fieldApiName.includes('.')) {
            const parts = fieldApiName.split('.');
            let value = this.record;
            for (const part of parts) {
                if (value && typeof value === 'object') {
                    value = value[part];
                } else {
                    return '';
                }
            }
            return value || '';
        }
        
        // Direct field access
        return this.record[fieldApiName] || '';
    }
}