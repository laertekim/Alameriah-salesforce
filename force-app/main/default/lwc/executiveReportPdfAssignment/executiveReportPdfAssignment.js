import { LightningElement, api, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { CloseActionScreenEvent } from 'lightning/actions';

import JSPDF from '@salesforce/resourceUrl/jspdf';
import AUTOTABLE from '@salesforce/resourceUrl/jspdf_autotable';
import LOGO from '@salesforce/resourceUrl/AlameriahDLogo';

import getAssignments from '@salesforce/apex/ExecutiveReportAssignmentsLwcController.getAssignments';
import savePdfFromLwc from '@salesforce/apex/ExecutiveReportAssignmentsLwcController.savePdfFromLwc';


export default class ExecutiveReportAssignmentsPdf extends LightningElement {
  @api recordId;
  @track isLoading = false;

  _libsLoaded = false;

  async loadLibsIfNeeded() {
    if (this._libsLoaded) return;
    await loadScript(this, JSPDF);
    await loadScript(this, AUTOTABLE);
    this._libsLoaded = true;
  }

  async loadImageAsDataUrl(url) {
    const resp = await fetch(url);
    const blob = await resp.blob();

    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result);
      reader.onerror = reject;
      reader.readAsDataURL(blob);
    });
  }

  stripHtmlToText(html) {
    if (!html) return '';

    let s = String(html)
      .replace(/<br\s*\/?>/gi, '\n')
      .replace(/<\/p>/gi, '\n')
      .replace(/<\/div>/gi, '\n')
      .replace(/<\/li>/gi, '\n');

    s = s.replace(/<[^>]+>/g, '');

    const textarea = document.createElement('textarea');
    textarea.innerHTML = s;
    s = textarea.value;

    s = s.replace(/\u00A0/g, ' ');
    s = s.replace(/[ \t]+\n/g, '\n');
    s = s.replace(/\n{3,}/g, '\n\n');
    return s.trim();
  }

  formatDateDDMMYYYY(date) {
    const d = date instanceof Date ? date : new Date(date);
    const dd = String(d.getDate()).padStart(2, '0');
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const yyyy = d.getFullYear();
    return `${dd}.${mm}.${yyyy}`;
  }

  fileName() {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    const dateStr = `${yyyy}${mm}${dd}`;
    const recordId = this.recordId || 'record';
    return `ExecutiveReport__${recordId}_${dateStr}.pdf`;
  }

  resolveStatusColorByValue(status) {
    if (!status) return [0, 0, 0];
    const s = String(status).toLowerCase();

    if (s.includes('done')) return [128, 128, 128];       // #808080
    if (s.includes('in progress')) return [255, 140, 0];  // #FF8C00
    if (s.includes('related')) return [50, 205, 50];      // #32CD32
    if (s.includes('pending')) return [255, 0, 0];        // #FF0000

    return [0, 0, 0];
  }

  drawHeader(doc, ctx) {
    const { marginLeft, marginTop, pageWidth, headerHeight, logoDataUrl, reportDateStr } = ctx;

    doc.setDrawColor(22, 50, 92);
    doc.setLineWidth(0.3);
    doc.line(marginLeft, marginTop + headerHeight, pageWidth - marginLeft, marginTop + headerHeight);

    if (logoDataUrl) {
      doc.addImage(logoDataUrl, 'PNG', marginLeft, marginTop + 2, 40, 16);
    }

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(18);
    doc.setTextColor(22, 50, 92);
    doc.text('Dashboard: Tasks, Ref.', pageWidth - marginLeft, marginTop + 10, { align: 'right' });

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(11);
    doc.setTextColor(112, 110, 107);
    doc.text(reportDateStr, pageWidth - marginLeft, marginTop + 16, { align: 'right' });
  }

  drawLegend(doc, ctx) {
    const { marginLeft, legendTop } = ctx;

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(10);
    doc.setTextColor(62, 62, 60);
    doc.text('Legend:', marginLeft, legendTop);

    const items = [
      { label: 'Done', rgb: [128, 128, 128] },
      { label: 'In Progress', rgb: [255, 140, 0] },
      { label: 'Related Task', rgb: [50, 205, 50] },
      { label: 'Pending / Requires ExCom Approval', rgb: [255, 0, 0] }
    ];

    let x = marginLeft + 18;
    const yBox = legendTop - 4;

    for (const it of items) {
      doc.setFillColor(...it.rgb);
      doc.roundedRect(x, yBox, 8, 4, 1, 1, 'F');

      doc.setFont('helvetica', 'normal');
      doc.setTextColor(62, 62, 60);
      doc.text(it.label, x + 10, legendTop);

      x += Math.min(10 + doc.getTextWidth(it.label) + 18, 110);
    }
  }

  drawFooter(doc, ctx) {
    const { marginLeft, pageWidth, pageHeight, marginBottom } = ctx;

    const pageNumber = doc.internal.getCurrentPageInfo().pageNumber;
    const footerY = pageHeight - marginBottom + 8;

    doc.setDrawColor(160, 160, 160);
    doc.setLineWidth(0.3);
    doc.line(marginLeft, footerY - 6, pageWidth - marginLeft, footerY - 6);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.setTextColor(112, 110, 107);
    doc.text(`${pageNumber} | Page`, marginLeft, footerY);

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(9);
    doc.setTextColor(112, 110, 107);
    doc.text('DEVELOPMENT DEPARTMENT', marginLeft + 35, footerY);
  }

  // Measurement pass to determine which page each row will be on
  measureRowPages(jsPDF, head, body, tableTopY, margins, tableWidth, styles, headStyles, columnStyles, ctx) {
    const measureDoc = new jsPDF({ orientation: 'landscape', unit: 'mm', format: 'a4' });
    const rowPageMap = {};

    measureDoc.autoTable({
      head,
      body,
      startY: tableTopY,
      margin: { left: margins.left, right: margins.right, top: tableTopY, bottom: margins.bottom },
      tableWidth,
      styles,
      headStyles,
      columnStyles,
      showHead: 'everyPage',

      didDrawCell: (data) => {
        if (data.section === 'body' && data.column.index === 0) {
          rowPageMap[data.row.index] = data.pageNumber;
        }
      },

      didDrawPage: (data) => {
        this.drawHeader(measureDoc, ctx);
        this.drawLegend(measureDoc, ctx);
        this.drawFooter(measureDoc, ctx);
      }
    });

    return rowPageMap;
  }

  // Compute rowSpan for project column based on page boundaries
  computeProjectRowSpans(body, rowPageMap) {
    const rowSpans = {};
    
    let i = 0;
    while (i < body.length) {
      const currentPage = rowPageMap[i];
      const currentProject = body[i][1]; // Project name is in column 1
      
      let spanCount = 1;
      let j = i + 1;
      
      // Count consecutive rows with same project on same page
      while (j < body.length && 
             rowPageMap[j] === currentPage && 
             body[j][1] === currentProject) {
        spanCount++;
        j++;
      }
      
      // Set rowSpan for first row and 0 for subsequent rows
      rowSpans[i] = spanCount;
      for (let k = i + 1; k < j; k++) {
        rowSpans[k] = 0; // Hide these cells
      }
      
      i = j;
    }
    
    return rowSpans;
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  async handleGenerate() {
    this.isLoading = true;

    try {
      await this.loadLibsIfNeeded();

      const jsPDF = window.jspdf?.jsPDF;
      if (!jsPDF) throw new Error('jsPDF not found (window.jspdf.jsPDF)');

      const rows = await getAssignments({ executiveReportId: this.recordId });

      const logoDataUrl = await this.loadImageAsDataUrl(LOGO);

      const doc = new jsPDF({ orientation: 'landscape', unit: 'mm', format: 'a4' });

      const pageWidth = doc.internal.pageSize.getWidth();
      const pageHeight = doc.internal.pageSize.getHeight();

      const marginLeft = 10;
      const marginRight = 10;
      const marginTop = 10;
      const marginBottom = 20;

      const headerHeight = 22;
      const reportDateStr = this.formatDateDDMMYYYY(new Date());

      const ctx = {
        pageWidth,
        pageHeight,
        marginLeft,
        marginRight,
        marginTop,
        marginBottom,
        headerHeight,
        legendTop: marginTop + headerHeight + 8,
        logoDataUrl,
        reportDateStr
      };

      const head = [[
        'Item',
        'Project / Name',
        'Assignment Description',
        'Next Action / Decision Required',
        'Action By',
        'Target / Status',
        'Priority / Notes'
      ]];

      // Build flat body array with all rows
      const body = [];
      const statusMap = {};
      let itemCounter = 1;

      (rows || []).forEach((a) => {
        const projectName = a.Project__r?.Name || a.Name || '';
        const rowData = [
          itemCounter++,
          projectName,
          this.stripHtmlToText(a.Assignment_Description__c),
          this.stripHtmlToText(a.Next_Action_Decision_Required__c),
          a.Action_By__r?.Name ?? '',
          a.Target_Status__c ?? '',
          this.stripHtmlToText(a.Priority_Notes__c)
        ];
        
        body.push(rowData);
        statusMap[body.length - 1] = String(rowData[5] ?? '').trim();
      });

      const tableWidth = pageWidth - marginLeft - marginRight;

      const base = [12, 38, 52, 70, 28, 28, 40];
      const sum = base.reduce((acc, v) => acc + v, 0);
      const w = base.map(v => (v / sum) * tableWidth);

      const tableTopY = ctx.legendTop + 6;

      const styles = {
        font: 'helvetica',
        fontSize: 9,
        cellPadding: 3,
        valign: 'top',
        lineColor: [0, 0, 0],
        lineWidth: 0.2,
        textColor: [62, 62, 60],
        overflow: 'linebreak'
      };

      const headStyles = {
        fillColor: [22, 50, 92],
        textColor: [255, 255, 255],
        fontStyle: 'bold',
        lineColor: [0, 0, 0],
        lineWidth: 0.2
      };

      const columnStyles = {
        0: { cellWidth: w[0], halign: 'center', fontStyle: 'bold' },
        1: { cellWidth: w[1], halign: 'center', valign: 'middle', fontStyle: 'bold' },
        2: { cellWidth: w[2] },
        3: { cellWidth: w[3] },
        4: { cellWidth: w[4] },
        5: { cellWidth: w[5], halign: 'center' },
        6: { cellWidth: w[6] }
      };

      // STEP 1: Measurement pass to determine page layout
      const rowPageMap = this.measureRowPages(
        jsPDF, head, body, tableTopY,
        { left: marginLeft, right: marginRight, bottom: marginBottom },
        tableWidth, styles, headStyles, columnStyles, ctx
      );

      // STEP 2: Compute rowSpans for project column
      const projectRowSpans = this.computeProjectRowSpans(body, rowPageMap);

      // STEP 3: Actual render with merged cells
      doc.autoTable({
        head,
        body,
        startY: tableTopY,
        margin: { left: marginLeft, right: marginRight, top: tableTopY, bottom: marginBottom },
        tableWidth,
        showHead: 'everyPage',
        styles,
        headStyles,
        tableLineColor: [0, 0, 0],
        tableLineWidth: 0.6,
        columnStyles,

        didParseCell: (data) => {
          // Handle project column merging
          if (data.section === 'body' && data.column.index === 1) {
            const rowIndex = data.row.index;
            const span = projectRowSpans[rowIndex];
            
            if (span > 1) {
              data.cell.rowSpan = span;
            } else if (span === 0) {
              // Hide this cell (it's part of a merged cell above)
              data.cell.styles.fillColor = false;
              data.cell.styles.textColor = false;
              data.cell.text = '';
            }
            
            // Style for visible project cells
            if (span >= 1) {
              data.cell.styles.fillColor = [22, 50, 92];
              data.cell.styles.textColor = [255, 255, 255];
              data.cell.styles.fontStyle = 'bold';
              data.cell.styles.halign = 'center';
              data.cell.styles.valign = 'middle';
            }
          }

          // Handle status column coloring
          if (data.section === 'body' && data.column.index === 5) {
            const rowIndex = data.row.index;
            const statusText = statusMap[rowIndex] || '';
            
            if (statusText) {
              const rgb = this.resolveStatusColorByValue(statusText);
              data.cell.styles.textColor = rgb;

              if (statusText.toLowerCase().includes('pending')) {
                data.cell.styles.fontStyle = 'bold';
              }
            }
          }
        },

        didDrawPage: () => {
          this.drawHeader(doc, ctx);
          this.drawLegend(doc, ctx);
          this.drawFooter(doc, ctx);
        }
      });

      doc.save(this.fileName());
      
      const dataUri = doc.output('datauristring');
      const base64 = dataUri.split('base64,')[1];
      const fileName = `Executive Report Assignments - ${this.formatDateDDMMYYYY(new Date())}.pdf`;

      await savePdfFromLwc({
        reportId: this.recordId,
        base64Data: base64,
        fileName: fileName
      });

      setTimeout(() => {
        this.handleCancel();
      }, 500);
    } catch (e) {
      console.error(e);
      alert(e?.message || 'Error generating PDF');
    } finally {
      this.isLoading = false;
    }
  }
}