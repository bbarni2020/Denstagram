//
//  InstagramWebView.swift
//  Denstagram
//
//  Created by Balogh Barnabás on 2025. 10. 26..
//

import SwiftUI
import WebKit

struct InstagramWebView: UIViewRepresentable {
    @Binding var isLoading: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let hideElementsScript = WKUserScript(
            source: context.coordinator.getHideElementsJS(),
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(hideElementsScript)
        
        let blockCommentsScript = WKUserScript(
            source: context.coordinator.getBlockCommentsJS(),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(blockCommentsScript)
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        if let url = URL(string: "https://www.instagram.com/direct/inbox/") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Nothing to update for now
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: InstagramWebView
        
        init(_ parent: InstagramWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            
            webView.evaluateJavaScript(getHideElementsJS()) { _, error in
                if let error = error {
                    print("JS injection error: \(error)")
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            
            let urlString = url.absoluteString
            let path = url.path
            
            if urlString.contains("accounts/login") ||
               urlString.contains("accounts/emailsignup") ||
               urlString.contains("accounts/password") ||
               urlString.contains("challenge") ||
               urlString.contains("accounts/two_factor") {
                decisionHandler(.allow)
                return
            }
            
            if path.hasPrefix("/direct/") ||
               path.hasPrefix("/direct/inbox") ||
               path.hasPrefix("/direct/t/") {
                decisionHandler(.allow)
                return
            }

            if path.contains("accounts/activity") ||
               urlString.contains("follow") ||
               urlString.contains("follower") {
                decisionHandler(.allow)
                return
            }
            

            if path.contains("/reel/") || path.contains("/p/") {
                decisionHandler(.allow)
                return
            }

            if urlString.contains("/api/") ||
               urlString.contains("cdninstagram") ||
               urlString.contains("fbcdn") ||
               url.scheme == "blob" ||
               url.scheme == "data" {
                decisionHandler(.allow)
                return
            }

            if path == "/" ||
               path.hasPrefix("/explore") ||
               path.hasPrefix("/reels") ||
               path.hasPrefix("/tv") ||
               urlString.contains("instagram.com") && !path.hasPrefix("/direct") {
                if let dmURL = URL(string: "https://www.instagram.com/direct/inbox/") {
                    webView.load(URLRequest(url: dmURL))
                }
                decisionHandler(.cancel)
                return
            }
            
            if !urlString.contains("instagram.com") && !urlString.contains("facebook.com") {
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        func getHideElementsJS() -> String {
            return """
            (function() {
                // Hide bottom navigation bar
                const hideNav = () => {
                    const navSelectors = [
                        'nav[role="navigation"]',
                        'div[role="navigation"]',
                        'section > div > div > div > div > div > nav',
                        'a[href="/"]',
                        'a[href="#"]',
                        'header nav',
                        'section nav'
                    ];
                    
                    navSelectors.forEach(selector => {
                        document.querySelectorAll(selector).forEach(el => {
                            // Only hide if it contains home/explore/reels links
                            const innerHTML = el.innerHTML.toLowerCase();
                            if (innerHTML.includes('explore') || 
                                innerHTML.includes('reels') ||
                                el.querySelector('a[href="/"]')) {
                                const parent = el.parentElement;
                                if (parent && !parent.innerHTML.includes('direct')) {
                                    el.style.display = 'none';
                                }
                            }
                        });
                    });
                    
                    // Hide specific navigation items
                    document.querySelectorAll('a').forEach(link => {
                        const href = link.getAttribute('href') || '';
                        if (href === '/' || 
                            href.startsWith('/explore') || 
                            href.startsWith('/reels') ||
                            href.startsWith('/?')) {
                            link.style.display = 'none';
                            if (link.parentElement) {
                                link.parentElement.style.display = 'none';
                            }
                        }
                    });
                };
                
                // Block reel scrolling
                const blockReelScroll = () => {
                    if (window.location.pathname.includes('/reel/') || 
                        window.location.pathname.includes('/p/')) {
                        // Disable scroll
                        document.body.style.overflow = 'hidden';
                        document.documentElement.style.overflow = 'hidden';
                        
                        // Block swipe gestures for reel navigation
                        let touchStartY = 0;
                        document.addEventListener('touchstart', (e) => {
                            touchStartY = e.touches[0].clientY;
                        }, { passive: false });
                        
                        document.addEventListener('touchmove', (e) => {
                            const touchEndY = e.touches[0].clientY;
                            const diff = Math.abs(touchEndY - touchStartY);
                            
                            // Block significant vertical swipes (reel navigation)
                            if (diff > 50) {
                                e.preventDefault();
                                e.stopPropagation();
                            }
                        }, { passive: false });
                    }
                };
                
                // Hide comment sections
                const hideComments = () => {
                    // Hide comment input and comment sections
                    const commentSelectors = [
                        'section[role="dialog"]',
                        'form[method="POST"]',
                        'textarea[placeholder*="comment" i]',
                        'textarea[placeholder*="Add a comment" i]',
                        'div[role="button"][tabindex="0"]'
                    ];
                    
                    commentSelectors.forEach(selector => {
                        document.querySelectorAll(selector).forEach(el => {
                            const text = el.textContent?.toLowerCase() || '';
                            const placeholder = el.getAttribute('placeholder')?.toLowerCase() || '';
                            
                            if (text.includes('comment') || 
                                placeholder.includes('comment') ||
                                text.includes('add a comment')) {
                                el.style.display = 'none';
                            }
                        });
                    });
                };
                
                // Run immediately
                hideNav();
                blockReelScroll();
                hideComments();
                
                // Re-run when DOM changes
                const observer = new MutationObserver(() => {
                    hideNav();
                    blockReelScroll();
                    hideComments();
                });
                
                observer.observe(document.body, {
                    childList: true,
                    subtree: true
                });
                
                // Re-run on navigation
                let lastPath = window.location.pathname;
                setInterval(() => {
                    if (window.location.pathname !== lastPath) {
                        lastPath = window.location.pathname;
                        setTimeout(() => {
                            hideNav();
                            blockReelScroll();
                            hideComments();
                        }, 500);
                    }
                }, 100);
            })();
            """
        }
        
        func getBlockCommentsJS() -> String {
            return """
            (function() {
                // Block comment posting at the network level
                const originalFetch = window.fetch;
                window.fetch = function(...args) {
                    const url = args[0]?.toString() || '';
                    
                    // Block comment API calls
                    if (url.includes('/comment/') || 
                        url.includes('/web/comments/')) {
                        console.log('Blocked comment request');
                        return Promise.reject(new Error('Comments disabled'));
                    }
                    
                    return originalFetch.apply(this, args);
                };
                
                // Block XMLHttpRequest comment posts
                const originalXHR = window.XMLHttpRequest.prototype.open;
                window.XMLHttpRequest.prototype.open = function(method, url, ...rest) {
                    if (url.includes('/comment/') || url.includes('/web/comments/')) {
                        console.log('Blocked XHR comment request');
                        return;
                    }
                    return originalXHR.apply(this, [method, url, ...rest]);
                };
            })();
            """
        }
    }
}
