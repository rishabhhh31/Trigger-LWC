import { LightningElement, track } from "lwc";
import { getBarcodeScanner } from "lightning/mobileCapabilities";

export default class BarcodeScanner extends LightningElement {
    barcodeScanner;
    @track scannedBarcodes;

    connectedCallback() {
        // Initialize the BarcodeScanner utility once the component is loaded
        this.barcodeScanner = getBarcodeScanner();
    }

    beginScanning() {
        // Ensure BarcodeScanner is available (works only on Salesforce mobile app, not desktop)
        if (this.barcodeScanner != null && this.barcodeScanner.isAvailable()) {

            // Scanning options: configure how the scanner behaves
            const scanningOptions = {
                barcodeTypes: [this.barcodeScanner.barcodeTypes.QR], // Supported types: QR, CODE128, EAN13, etc.
                scannerSize: "FULLSCREEN", // Fullscreen camera view
                instructionText: "Align the barcode inside the frame", // Text shown to user before scanning
                successText: "Scan successful", // Confirmation text shown after a scan
                vibrateOnSuccess: true, // Device vibrates on successful scan
                cameraFacing: "BACK", // Use back camera
                showSuccessCheckMark: true, // Display check mark on success
                enableBulkScan: true, // Allow scanning multiple barcodes in one go
                enableMultiScan: true // Keep scanning until user taps Done
            };

            // Reset scanned barcodes before starting a new scanning session
            this.scannedBarcodes = [];

            // Start the scanning session
            this.barcodeScanner
                .scan(scanningOptions)
                .then((results) => {
                    // Results is an array of scanned barcodes (because multi-scan is enabled)
                    this.processScannedBarcodes(results);
                })
                .catch((error) => {
                    // Handle any errors from the scanner
                    this.processError(error);
                })
                .finally(() => {
                    // Always dismiss the scanner view once scanning ends
                    this.barcodeScanner.dismiss();
                });
        } else {
            console.log("BarcodeScanner unavailable. Likely running on a non-mobile device.");
        }
    }

    processScannedBarcodes(barcodes) {
        // Process scanned barcodes:
        // - Look up records in Salesforce
        // - Create or update data
        // - Populate form fields
        // - Or just display the results

        // Merge new barcodes into the tracked array
        this.scannedBarcodes = this.scannedBarcodes.concat(barcodes);
    }

    processError(error) {
        // Handle different types of errors
        if (error.code === "USER_DISMISSED") {
            console.log("ℹ️ User ended the scanning session.");
        } else {
            console.error("❌ Scanning error:", error);
        }
    }

    get scannedBarcodesAsString() {
        // Convert scanned barcodes into a string for display in the UI
        return this.scannedBarcodes.map((barcode) => barcode.value).join("\n");
    }
}