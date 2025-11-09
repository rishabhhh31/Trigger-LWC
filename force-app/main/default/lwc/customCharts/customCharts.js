import { LightningElement, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import ChartJs from '@salesforce/resourceUrl/ChartJs';
import getOpportunitiesByStages from '@salesforce/apex/ChartHandler.getOpportunitiesByStages';
import getAccountsByIndustry from '@salesforce/apex/ChartHandler.getAccountsByIndustry';
import getCasesByStatus from '@salesforce/apex/ChartHandler.getCasesByStatus';
export default class CustomCharts extends LightningElement {
    isChartJsInitialized = false;
    connectedCallback() {
        if (this.isChartJsInitialized) {
            return;
        }
        this.isChartJsInitialized = true;
        Promise.all([
            loadScript(this, ChartJs)
        ])
            .then(() => {
                // Chart.js library loaded
                this.displayOpportunitiesByStages();
                this.displayAccountsByIndustry();
                this.displayCasesByStatus();
            })
            .catch(error => {
                console.error(JSON.stringify(error));
            });
    }

    async displayOpportunitiesByStages() {
        try {
            const stageCounts = await getOpportunitiesByStages();
            const ctx = this.template.querySelector('.opportunity-stage').getContext('2d');
            const data = {
                labels: Object.keys(stageCounts),
                datasets: [{
                    label: 'Opportunities by Stage',
                    data: Object.values(stageCounts),
                    backgroundColor: [
                        '#FF6384', '#36A2EB', '#FFCE56',
                        '#4BC0C0', '#9966FF', '#FF9F40',
                        '#C9CBCF', '#8BC34A', '#E91E63'
                    ],
                    hoverOffset: 18,               // expands arc on hover
                }]
            };

            const config = {
                type: 'doughnut',
                data: data,
                options: {
                    cutout: '50%',        // inner hollow area
                    radius: '90%',        // outer radius as percentage
                    rotation: -90,        // start at top
                    circumference: 360,   // full circle
                    animation: {
                        animateRotate: true,
                        animateScale: true
                    },
                    plugins: {
                        legend: {
                            position: 'bottom'
                        },
                        tooltip: {
                            callbacks: {
                                label: (context) => `${context.label}: ${context.parsed}`
                            }
                        }
                    },
                }
            };

            // Render chart
            new window.Chart(ctx, config);

        } catch (error) {
            console.error('Error fetching Opportunity data: ', error);
        }
    }

    async displayAccountsByIndustry() {
        try {
            const industryData = await getAccountsByIndustry();
            console.log(industryData);
            const ctx = this.template.querySelector('.account-industry').getContext('2d');
            const data = {
                labels: Object.keys(industryData),
                datasets: [{
                    label: 'Accounts by Industry',
                    data: Object.values(industryData),
                    backgroundColor: [
                        '#4CAF50',   // Agriculture
                        '#E91E63',   // Apparel
                        '#3F51B5',   // Banking
                        '#9C27B0',   // Biotechnology
                        '#FF5722',   // Chemicals
                        '#00BCD4',   // Communications
                        '#795548',   // Construction
                        '#607D8B',   // Consulting
                        '#FF9800',   // Education
                        '#2196F3',   // Electronics
                        '#FFEB3B',   // Energy
                        '#8BC34A',   // Engineering
                        '#9E9E9E',   // Entertainment
                        '#009688',   // Environmental
                        '#673AB7',   // Finance
                        '#CDDC39',   // Food & Beverage
                        '#3E2723',   // Government
                        '#F44336',   // Healthcare
                        '#FF7043',   // Hospitality
                        '#6A1B9A',   // Insurance
                        '#1E88E5',   // Machinery
                        '#43A047',   // Manufacturing
                        '#BA68C8',   // Media
                        '#AED581',   // Not For Profit
                        '#FFB300',   // Recreation
                        '#F06292',   // Retail
                        '#5C6BC0',   // Shipping
                        '#0288D1',   // Technology
                        '#26A69A',   // Telecommunications
                        '#8D6E63',   // Transportation
                        '#FFA726',   // Utilities
                        '#9E9E9E'    // Other
                    ],
                }]
            };

            const config = {
                type: 'polarArea',
                data: data,
                options: {
                    scales: {
                        r: {
                            beginAtZero: true,
                            grid: { circular: true },
                            ticks: {
                                stepSize: 2,
                                color: '#555'
                            }
                        }
                    },
                    plugins: {
                        title: {
                            display: false,
                            text: 'Accounts by Industry'
                        },
                        legend: {
                            position: 'bottom'
                        },
                        tooltip: {
                            callbacks: {
                                label: function (context) {
                                    return `${context.label}: ${context.formattedValue} Accounts`;
                                }
                            }
                        }
                    },
                    animation: {
                        animateRotate: true,
                        animateScale: true
                    }
                }
            };

            // Render chart
            new window.Chart(ctx, config);

        } catch (error) {
            console.error('Error fetching Opportunity data: ', error);
        }
    }

    async displayCasesByStatus() {
        try {
            const caseData = await getCasesByStatus();
            const ctx = this.template.querySelector('.case-status').getContext('2d');

            const labels = Object.keys(caseData);
            const values = Object.values(caseData);

            const backgroundColors = [
                '#42A5F5', // New
                '#66BB6A', // Working
                '#FFCA28', // Escalated
                '#EF5350'  // Closed
            ];

            const data = {
                labels: labels,
                datasets: [{
                    label: 'Number of Cases',
                    data: values,
                    backgroundColor: backgroundColors.slice(0, labels.length),
                    borderWidth: 1,
                    borderRadius: 5
                }]
            };

            const config = {
                type: 'bar',
                data: data,
                options: {
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: {
                                stepSize: 1
                            },
                            title: {
                                display: true,
                                text: 'Number of Cases'
                            }
                        },
                        x: {
                            title: {
                                display: true,
                                text: 'Case Status'
                            }
                        }
                    },
                    plugins: {
                        title: {
                            display: false,
                            text: 'Cases by Status'
                        },
                        legend: {
                            position: 'top'
                        },
                        tooltip: {
                            callbacks: {
                                label: (context) => `${context.label}: ${context.formattedValue} cases`
                            }
                        }
                    },
                    animation: {
                        duration: 1200,
                        easing: 'easeOutBounce'
                    }
                }
            };

            new window.Chart(ctx, config);
        } catch (error) {
            console.error('Error fetching Case data: ', error);
        }
    }
}