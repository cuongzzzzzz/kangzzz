// Enterprise Web Frontend JavaScript
class EnterpriseApp {
    constructor() {
        this.apiBaseUrl = '/api';
        this.init();
    }

    init() {
        this.loadStats();
        this.setupEventListeners();
        this.startHealthCheck();
    }

    setupEventListeners() {
        document.getElementById('test-api')?.addEventListener('click', () => this.testApiConnection());
        document.getElementById('load-data')?.addEventListener('click', () => this.loadSampleData());
    }

    async loadStats() {
        try {
            const response = await fetch('/health');
            const data = await response.json();
            
            this.updateStats(data);
        } catch (error) {
            console.error('Failed to load stats:', error);
            this.updateStats({ uptime: 'Error', requests: 'Error', responseTime: 'Error' });
        }
    }

    updateStats(data) {
        const uptimeElement = document.getElementById('uptime');
        const requestsElement = document.getElementById('requests');
        const responseTimeElement = document.getElementById('response-time');

        if (uptimeElement) {
            uptimeElement.textContent = data.uptime ? `${Math.floor(data.uptime / 3600)}h` : '--';
        }

        if (requestsElement) {
            requestsElement.textContent = data.requests || '--';
        }

        if (responseTimeElement) {
            responseTimeElement.textContent = data.responseTime ? `${data.responseTime}ms` : '--';
        }
    }

    async testApiConnection() {
        const button = document.getElementById('test-api');
        const responseDiv = document.getElementById('api-response');
        
        if (button) {
            button.disabled = true;
            button.innerHTML = '<span class="loading"></span> Testing...';
        }

        try {
            const response = await fetch(`${this.apiBaseUrl}/health`);
            const data = await response.json();
            
            if (responseDiv) {
                responseDiv.innerHTML = `
                    <h4>API Connection Test</h4>
                    <p><strong>Status:</strong> <span class="status-healthy">✓ Connected</span></p>
                    <p><strong>Response Time:</strong> ${Date.now() - performance.now()}ms</p>
                    <pre>${JSON.stringify(data, null, 2)}</pre>
                `;
            }
        } catch (error) {
            console.error('API Test Error:', error);
            if (responseDiv) {
                responseDiv.innerHTML = `
                    <h4>API Connection Test</h4>
                    <p><strong>Status:</strong> <span class="status-error">✗ Failed</span></p>
                    <p><strong>Error:</strong> ${error.message}</p>
                `;
            }
        } finally {
            if (button) {
                button.disabled = false;
                button.textContent = 'Test API Connection';
            }
        }
    }

    async loadSampleData() {
        const button = document.getElementById('load-data');
        const responseDiv = document.getElementById('api-response');
        
        if (button) {
            button.disabled = true;
            button.innerHTML = '<span class="loading"></span> Loading...';
        }

        try {
            const response = await fetch(`${this.apiBaseUrl}/users`);
            const data = await response.json();
            
            if (responseDiv) {
                responseDiv.innerHTML = `
                    <h4>Sample Data Loaded</h4>
                    <p><strong>Records:</strong> ${data.length || 0}</p>
                    <pre>${JSON.stringify(data, null, 2)}</pre>
                `;
            }
        } catch (error) {
            console.error('Data Load Error:', error);
            if (responseDiv) {
                responseDiv.innerHTML = `
                    <h4>Data Load Failed</h4>
                    <p><strong>Error:</strong> ${error.message}</p>
                    <p>This is expected if the API service is not fully configured yet.</p>
                `;
            }
        } finally {
            if (button) {
                button.disabled = false;
                button.textContent = 'Load Sample Data';
            }
        }
    }

    startHealthCheck() {
        // Check health every 30 seconds
        setInterval(() => {
            this.loadStats();
        }, 30000);
    }
}

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new EnterpriseApp();
});

// Service Worker for offline functionality
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/sw.js')
            .then(registration => {
                console.log('SW registered: ', registration);
            })
            .catch(registrationError => {
                console.log('SW registration failed: ', registrationError);
            });
    });
}
