import { asn1, pki, pkcs7 } from "node-forge";

const EXPECTED_BUNDLE_ID = "com.toastcat.maculate";
const APPLE_ROOT_CERT = ``; // read root.pem at build time

export async function validateReceipt(receiptBase64) {
  try {
    const receiptBuffer = Uint8Array.from(atob(receiptBase64), (c) =>
      c.charCodeAt(0)
    );
    const p7 = pkcs7.messageFromAsn1(
      asn1.fromDer(String.fromCharCode(...receiptBuffer))
    );

    const rootCert = pki.certificateFromPem(APPLE_ROOT_CERT);
    const certChain = p7.certificates.map((cert) =>
      pki.certificateFromAsn1(asn1.fromDer(cert))
    );
    certChain.push(rootCert);

    const isValidSignature = p7.verify({
      caStore: certChain,
    });

    if (!isValidSignature) {
      return { valid: false, error: "Invalid signature" };
    }

    const payload = asn1.fromDer(p7.content!.toString());
    const receiptData = parseReceiptPayload(payload);

    const { bundleID, version, deviceHash } = receiptData;
    if (bundleID !== EXPECTED_BUNDLE_ID) {
      return { valid: false, error: "Mismatched bundle ID or version" };
    }

    return { valid: true, receiptData };
  } catch (error) {
    return { valid: false, error: error.message };
  }
}

// https://developer.apple.com/documentation/appstorereceipts/validating_receipts_on_the_device
function parseReceiptPayload(payload) {
  const receiptAttributes = payload.value || [];
  const parsedAttributes = {};

  receiptAttributes.forEach((attr) => {
    const type = attr[0].value;
    const value = attr[2].value;
    parsedAttributes[type] = value;
  });

  return {
    bundleID: parsedAttributes[2],
    version: parsedAttributes[3],
    deviceHash: parsedAttributes[5],
  };
}
