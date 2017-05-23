/*
 * The MIT License
 *
 * Copyright (c) 2017, CloudBees, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
package com.cloudbees.tftwoway;

import org.apache.commons.io.IOUtils;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.bouncycastle.util.io.pem.PemReader;

import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.KeyManager;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import java.io.BufferedInputStream;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URL;
import java.security.KeyFactory;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.SecureRandom;
import java.security.Security;
import java.security.cert.Certificate;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.security.spec.KeySpec;
import java.security.spec.PKCS8EncodedKeySpec;

/**
 * @author <a href="mailto:tom.fennelly@gmail.com">tom.fennelly@gmail.com</a>
 */
public class Client {
    
    // Run the nginx script in the root.
    
    static {
        // BouncyCastle is needed in order to read the private RSA keys.
        // JDK not able to read unless they are PKCS#8 encoded.
        Security.addProvider(new BouncyCastleProvider());
    }

    public static void main(String[] args) throws Exception {
        URL url = new URL("https://example.com");
        HttpsURLConnection connection = (HttpsURLConnection) url.openConnection();

        SSLContext sslContext = createSSLContext();
        connection.setSSLSocketFactory(sslContext.getSocketFactory());

        connection.connect();
        
        int responseCode = connection.getResponseCode();
        String response = IOUtils.toString(connection.getInputStream(), connection.getContentEncoding());
        System.out.println(responseCode);
        System.out.println(response);
    }

    private static SSLContext createSSLContext() throws Exception {
        KeyManager[] serverKeyManagers = getKeyManager();
        TrustManager[] serverTrustManagers = getTrustManager();

        SSLContext sslContext = SSLContext.getInstance("TLS");
        sslContext.init(serverKeyManagers, serverTrustManagers, new SecureRandom());

        return sslContext;
    }

    public static KeyManager[] getKeyManager() throws Exception {
        KeyManagerFactory keyManagerFactory = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
        KeyStore store = KeyStore.getInstance("JKS");

        PrivateKey clientKey = loadRSAKey("./certs/client.key");
        X509Certificate clientCert = loadX509Key("./certs/client.crt");
        
        store.load(null);
        store.setKeyEntry("key", clientKey, "123123".toCharArray(), new Certificate[] { clientCert });

        keyManagerFactory.init(store, "123123".toCharArray());

        return keyManagerFactory.getKeyManagers();
    }

    public static TrustManager[] getTrustManager() throws Exception {
        TrustManagerFactory trustManagerFactory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        KeyStore store = KeyStore.getInstance("JKS");
        X509Certificate cacerts = loadX509Key("./certs/ca.crt");

        store.load(null);
        store.setCertificateEntry("cert", cacerts);

        trustManagerFactory.init(store);

        return trustManagerFactory.getTrustManagers();
    }

    private static PrivateKey loadRSAKey(String path) throws Exception {
        try (InputStream fis = new FileInputStream(path)) {
            try (PemReader pemReader = new PemReader(new InputStreamReader(fis))) {
                byte[] pemBytes = pemReader.readPemObject().getContent();

                KeyFactory keyFactory = KeyFactory.getInstance("RSA", "BC");
                KeySpec spec = new PKCS8EncodedKeySpec(pemBytes);

                return keyFactory.generatePrivate(spec);
            }
        }
    }
    
    private static X509Certificate loadX509Key(String path) throws Exception {
        try (FileInputStream fis = new FileInputStream(path)) {
            return (X509Certificate) CertificateFactory.getInstance("X.509").generateCertificate(new BufferedInputStream(fis));
        }        
    }
}
