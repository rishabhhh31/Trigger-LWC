import { LightningElement, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import ChartJs from '@salesforce/resourceUrl/ChartJs';
import SALES_DATA from '@salesforce/apex/SalesChartController.getSalesData';

export default class SalesChart extends LightningElement {
    chart;
    selectedDataPoint;

    barChartActive = true;
    lineChartActive = false;
    pieChartActive = false;

    chartJsLoaded = false;

    @wire(SALES_DATA)
    salesData;

    renderedCallback() {
        if (this.chartJsLoaded) {
            return;
        }

        this.chartJsLoaded = true;

        Promise.all([
            loadScript(this, ChartJs)
        ])
            .then(() => {
                console.log("ChartJS Loaded");

                if (this.salesData.data) {
                    this.initializeChart();
                }
            })
            .catch((error) => {
                console.error("Error loading Chart.js:", error);
            });
    }

    initializeChart() {
        if (!this.salesData.data) {
            return;
        }
        this.createChart();
    }

    createChart() {
        const canvas = this.template.querySelector("canvas.salesChart");
        const ctx = canvas.getContext("2d");

        if (this.chart) {
            this.chart.destroy();
        }

        const data = this.prepareChartData();

        this.chart = new window.Chart(ctx, {
            type: this.getChartType(),
            data: data,
            options: {
                responsive: true,
                maintainAspectRatio: false,
                onClick: (event, elements) => {
                    if (elements.length > 0) {
                        const index = elements[0].index;
                        this.selectedDataPoint = {
                            label: data.labels[index],
                            value: data.datasets[0].data[index]
                        };
                    }
                }
            }
        });
    }

    prepareChartData() {
        const sales = this.salesData.data;
        return {
            labels: sales.map(item => item.Month),
            datasets: [
                {
                    label: "Sales Amount",
                    data: sales.map(item => item.Amount),
                    backgroundColor: [
                        "rgba(54, 162, 235, 0.5)",
                        "rgba(255, 99, 132, 0.5)",
                        "rgba(255, 206, 86, 0.5)"
                    ],
                    borderColor: "rgba(54, 162, 235, 1)",
                    borderWidth: 1
                }
            ]
        };
    }

    getChartType() {
        if (this.barChartActive) return "bar";
        if (this.lineChartActive) return "line";
        if (this.pieChartActive) return "pie";
        return "bar";
    }

    showBarChart() {
        this.barChartActive = true;
        this.lineChartActive = false;
        this.pieChartActive = false;
        this.createChart();
    }

    showLineChart() {
        this.barChartActive = false;
        this.lineChartActive = true;
        this.pieChartActive = false;
        this.createChart();
    }

    showPieChart() {
        this.barChartActive = false;
        this.lineChartActive = false;
        this.pieChartActive = true;
        this.createChart();
    }

    // Button variants
    get barButtonVariant() {
        return this.barChartActive ? "brand" : "neutral";
    }
    get lineButtonVariant() {
        return this.lineChartActive ? "brand" : "neutral";
    }
    get pieButtonVariant() {
        return this.pieChartActive ? "brand" : "neutral";
    }
}
