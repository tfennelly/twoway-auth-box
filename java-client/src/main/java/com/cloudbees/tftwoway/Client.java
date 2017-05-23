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

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.conn.scheme.Scheme;
import org.apache.http.conn.scheme.SchemeRegistry;
import org.apache.http.conn.ssl.SSLConnectionSocketFactory;
import org.apache.http.conn.ssl.SSLSocketFactory;
import org.apache.http.conn.ssl.TrustSelfSignedStrategy;
import org.apache.http.conn.ssl.X509HostnameVerifier;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.impl.conn.tsccm.ThreadSafeClientConnManager;
import org.apache.http.ssl.SSLContexts;
import org.apache.http.util.EntityUtils;
import org.toilelibre.libe.curl.Curl;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.KeyManager;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.net.URL;
import java.security.KeyStore;
import java.security.SecureRandom;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;

/**
 * @author <a href="mailto:tom.fennelly@gmail.com">tom.fennelly@gmail.com</a>
 */
public class Client {

    public static void main(String[] args) throws Exception {
        // Trust own CA and all self-signed certs
        // read in the keystore from the filesystem, this should contain a single keypair
        KeyStore keyStore = getKeyStore("/Users/tfennelly/projects/twoway-auth-box/intermediate/client/keystore.jks");
        KeyStore trustStore = getKeyStore("/Users/tfennelly/projects/twoway-auth-box/intermediate/client/truststore.jks");

        // set up the socketfactory, to use our keystore for client authentication.
        SSLSocketFactory socketFactory = new SSLSocketFactory(
                SSLSocketFactory.TLS,
                keyStore,
                "123123",
                trustStore,
                null,
                null,
                SSLSocketFactory.ALLOW_ALL_HOSTNAME_VERIFIER);

        // create and configure scheme registry
        SchemeRegistry registry = new SchemeRegistry();
        registry.register(new Scheme("https", 443, socketFactory));

        // create a client connection manager to use in creating httpclients
        ThreadSafeClientConnManager mgr = new ThreadSafeClientConnManager(registry);

        // create the client based on the manager, and use it to make the call
        DefaultHttpClient httpClient = new DefaultHttpClient(mgr);

        // create the method to execute
        HttpGet httpget = new HttpGet("https://example.com/");

        // execute the method
        CloseableHttpResponse response = httpClient.execute(httpget);

        System.out.println("Executing request " + httpget.getRequestLine());

        try {
            HttpEntity entity = response.getEntity();

            System.out.println("----------------------------------------");
            System.out.println(response.getStatusLine());
            EntityUtils.consume(entity);
        } finally {
            response.close();
        }
        
//        SSLContext sslcontext = SSLContexts.custom()
//                .loadTrustMaterial(keyStore, new TrustSelfSignedStrategy())
//                .build();
//        // Allow TLSv1 protocol only
//        SSLConnectionSocketFactory sslsf = new SSLConnectionSocketFactory(
//                sslcontext,
//                new String[]{"TLSv1"},
//                null,
//                SSLConnectionSocketFactory.getDefaultHostnameVerifier());
//        CloseableHttpClient httpclient = HttpClients.custom()
//                .setSSLSocketFactory(sslsf)
//                .build();
//        try {
//
//            HttpGet httpget = new HttpGet("https://DayaHouston/");
//
//            System.out.println("Executing request " + httpget.getRequestLine());
//
//            CloseableHttpResponse response = httpclient.execute(httpget);
//            try {
//                HttpEntity entity = response.getEntity();
//
//                System.out.println("----------------------------------------");
//                System.out.println(response.getStatusLine());
//                EntityUtils.consume(entity);
//            } finally {
//                response.close();
//            }
//        } finally {
//            httpclient.close();
//        }

        // curl -k -E certs/client.p12:aoeu -v https://localhost/
//        System.out.println(Curl.$("curl -k -E /Users/tfennelly/projects/cda-nginx-ssl/certs/client.p12:aoeu https://DayaHouston/"));
        
//        HttpsURLConnection.setDefaultHostnameVerifier(new HostnameVerifier() {
//            @Override
//            public boolean verify(String s, SSLSession sslSession) {
//                return true;
//            }
//        });
//
//        URL url = new URL("https://localhost");
//        
//        HttpsURLConnection connection = (HttpsURLConnection) url.openConnection();
//
//        SSLContext sslContext = createSSLContext();
//        connection.setSSLSocketFactory(sslContext.getSocketFactory());
//
//        connection.setRequestMethod("GET");
//
//        connection.connect();
//        
//        int responseCode = connection.getResponseCode();
//        System.out.println(responseCode);
    }

    private static SSLContext createSSLContext() throws Exception {
        KeyStore keyStore = getKeyStore("/Users/tfennelly/projects/cda-nginx-ssl/certs/client.p12");
        KeyManager[] serverKeyManagers = getKeyManagers(keyStore, "aoeu".toCharArray());
//        KeyStore trustStore = getKeyStore("../intermediate/client/truststore.jks");
//        TrustManager[] serverTrustManagers = getTrustManagers(trustStore);

        SSLContext sslContext = SSLContext.getInstance("TLS");
        sslContext.init(serverKeyManagers, null, new SecureRandom());

        return sslContext;
    }

    private static KeyStore getKeyStore(String path) throws Exception {
        try (FileInputStream fis = new FileInputStream(path)) {
            if (path.endsWith(".jks")) {
                KeyStore serverKeyStore = KeyStore.getInstance("JKS");
                serverKeyStore.load(fis, "123123".toCharArray());
                return serverKeyStore;
            } else if (path.endsWith(".p12")) {
                KeyStore serverKeyStore = KeyStore.getInstance("PKCS12");
                serverKeyStore.load(fis, "123123".toCharArray());
                return serverKeyStore;
            } else if (path.endsWith(".crt") || path.endsWith(".pem")) {
                X509Certificate cert = (X509Certificate) CertificateFactory.getInstance("X.509").generateCertificate(new BufferedInputStream(fis));

                KeyStore serverKeyStore = KeyStore.getInstance("JKS");
                serverKeyStore.load(null, null);
                serverKeyStore.setCertificateEntry(Integer.toString(1), cert);

                return serverKeyStore;
            } else {
                return null;
            }
        }
    }

    public static KeyManager[] getKeyManagers(KeyStore store, final char[] password) throws Exception {
        KeyManagerFactory keyManagerFactory = KeyManagerFactory.getInstance(
                KeyManagerFactory.getDefaultAlgorithm());
        keyManagerFactory.init(store, password);

        return keyManagerFactory.getKeyManagers();
    }

    public static TrustManager[] getTrustManagers(KeyStore store) throws Exception {
//        TrustManagerFactory trustManagerFactory =
//                TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
//        trustManagerFactory.init(store);
//
//        return trustManagerFactory.getTrustManagers();

        X509Certificate serverCerts = loadX509("../intermediate/server/server.crt");
        X509Certificate cacerts = loadX509("../intermediate/certs/ca-chain.cert.pem");

        return new TrustManager[] {
                new X509TrustManager() {
                    @Override
                    public void checkClientTrusted(X509Certificate[] x509Certificates, String s) throws CertificateException {
                    }
                    @Override
                    public void checkServerTrusted(X509Certificate[] x509Certificates, String s) throws CertificateException {
                    }
                    @Override
                    public X509Certificate[] getAcceptedIssuers() {
                        return new X509Certificate[] { cacerts };
                    }
                }
        };
    } 
    
    private static X509Certificate loadX509(String path) throws Exception {
        try (FileInputStream fis = new FileInputStream(path)) {
            return (X509Certificate) CertificateFactory.getInstance("X.509").generateCertificate(new BufferedInputStream(fis));
        }        
    }
}
