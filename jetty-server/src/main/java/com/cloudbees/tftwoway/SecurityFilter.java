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

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.StringReader;
import java.net.URLDecoder;
import java.nio.charset.Charset;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;

/**
 * @author <a href="mailto:tom.fennelly@gmail.com">tom.fennelly@gmail.com</a>
 */
public class SecurityFilter implements Filter {
    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        
    }

    @Override
    public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain filterChain) throws IOException, ServletException {
        X509Certificate[] certs = (X509Certificate[]) servletRequest.getAttribute("javax.servlet.request.X509Certificate");
        String responseString;

        if (certs != null && certs.length > 0) {
            // The request was signed/authenticated with a client cert
            responseString = certs[0].toString();
        } else {
            String clientCertText = ((HttpServletRequest)servletRequest).getHeader("X-SSL-Client-Cert");
            if (clientCertText != null) {
                // A client cert was sent in a HTTP header from Nginx.
                // Decode and clean the cert (remove nginx tabs etc) 
                clientCertText = cleanCert(clientCertText);
                try {
                    X509Certificate clientCert = toX509Cert(clientCertText);
                    responseString = clientCert.toString();
                } catch (Exception e) {
                    responseString = "*** Error decoding client cert: " + e.getMessage() + "\n\n[" + clientCertText + "]\n\n";
                }

            } else {
                // Or you could get it from somewhere else
                responseString = "*** No client cert";
            }
        }

        byte[] response = responseString.getBytes(Charset.forName("UTF-8"));;
        
        ((HttpServletResponse)servletResponse).setStatus(HttpServletResponse.SC_OK);
        servletResponse.setCharacterEncoding("UTF-8");
        servletResponse.setContentType("test/plain");
        servletResponse.setContentLength(response.length);
        servletResponse.getOutputStream().write(response);
    }

    @Override
    public void destroy() {

    }

    private static X509Certificate toX509Cert(String certText) throws Exception {
        try (InputStream byteStream = new ByteArrayInputStream(certText.getBytes())) {
            return (X509Certificate) CertificateFactory.getInstance("X.509").generateCertificate(new BufferedInputStream(byteStream));
        }
    }

    /**
     * Nginx poops all over the cert, inserting tabs etc. This function reverses that.
     */
    private static String cleanCert(String certText) throws IOException {
        String decodedCertText = URLDecoder.decode(certText, "UTF-8");
        BufferedReader bufferedReader = new BufferedReader(new StringReader(decodedCertText));
        StringBuilder stringBuilder = new StringBuilder();

        String line = bufferedReader.readLine();
        while (line != null) {
            if (stringBuilder.length() > 0) {
                stringBuilder.append("\n");
            }
            
            line = line.trim();
            if (!line.startsWith("---")) {
                // don't do this for the first and last lines.
                line = line.replace(" ", "+");
            }
            stringBuilder.append(line.trim());
            
            line = bufferedReader.readLine();
        }

        return stringBuilder.toString();
    }
}
