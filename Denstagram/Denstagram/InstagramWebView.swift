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
    @Binding var targetURL: String
    @Binding var isSignedOut: Bool
    
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
        webView.allowsBackForwardNavigationGestures = false
        
        if let url = URL(string: targetURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let currentURL = webView.url?.absoluteString else {
            if let url = URL(string: targetURL) {
                let request = URLRequest(url: url)
                webView.load(request)
            }
            return
        }
        
        if currentURL.contains("accounts/login") || 
           currentURL.contains("accounts/logout") ||
           currentURL.contains("accounts/emailsignup") ||
           currentURL.contains("challenge") {
            return
        }
        
        if currentURL == targetURL {
            return
        }
        
        let normalizedTarget = targetURL.replacingOccurrences(of: "https://www.instagram.com", with: "").lowercased()
        let normalizedCurrent = currentURL.replacingOccurrences(of: "https://www.instagram.com", with: "").lowercased()
        
        if normalizedTarget.isEmpty {
            return
        }
        
        if normalizedCurrent == normalizedTarget {
            return
        }
        
        if normalizedCurrent.contains("/direct/") && normalizedTarget.contains("/direct/") {
            return
        }
        
        if normalizedCurrent.contains("/accounts/activity") && normalizedTarget.contains("/accounts/activity") {
            return
        }
        
        if (normalizedCurrent.contains("show_notifications=true") && normalizedTarget.contains("show_notifications=true")) ||
           (normalizedCurrent == "/" && normalizedTarget.contains("show_notifications=true")) {
            return
        }
        
        if normalizedCurrent.contains("/accounts/edit") && normalizedTarget.contains("/accounts/edit") {
            return
        }
        
        if normalizedCurrent.contains("/explore/people") && normalizedTarget.contains("/explore/people") {
            return
        }
        
        if let url = URL(string: targetURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
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
            
            if let currentURL = webView.url?.absoluteString {
                print("✅ Finished loading: \(currentURL)")
                if currentURL.contains("accounts/login") {
                    parent.isSignedOut = true
                } else if currentURL.contains("/direct/") {
                    parent.isSignedOut = false
                }
                
                if currentURL.contains("show_notifications=true") {
                    webView.evaluateJavaScript("""
                        (function() {
                            document.querySelectorAll('main, article, section').forEach(el => {
                                if (!el.querySelector('[role="dialog"]') && !el.closest('[role="dialog"]')) {
                                    el.style.display = 'none';
                                }
                            });
                            
                            const notifButton = document.querySelector('a[href*="/accounts/activity"]') || 
                                               document.querySelector('svg[aria-label*="Notifications"]')?.closest('a') ||
                                               document.querySelector('svg[aria-label*="Értesítések"]')?.closest('a');
                            if (notifButton) {
                                notifButton.click();
                                setTimeout(() => {
                                    document.body.style.overflow = 'hidden';
                                }, 100);
                            }
                        })();
                    """) { _, _ in }
                }
            }
            
            webView.evaluateJavaScript("document.body.innerHTML.length") { result, error in
                if let length = result as? Int {
                    print("📄 Page content length: \(length)")
                }
            }
            
            webView.evaluateJavaScript(getHideElementsJS()) { _, error in
                if let error = error {
                    print("JS injection error: \(error)")
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            print("❌ Navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            print("❌ Provisional navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            
            let urlString = url.absoluteString
            let path = url.path
            
            print("🔍 Navigation request: \(urlString)")
            
            if urlString.contains("facebook.com/instagram/login_sync") {
                print("🚫 Blocked Facebook sync")
                decisionHandler(.cancel)
                return
            }
            
            if urlString.contains("accounts/login") ||
               urlString.contains("accounts/emailsignup") ||
               urlString.contains("accounts/password") ||
               urlString.contains("challenge") ||
               urlString.contains("accounts/two_factor") {
                parent.isSignedOut = urlString.contains("accounts/login") || urlString.contains("accounts/logout")
                print("✅ Allowing auth page")
                decisionHandler(.allow)
                return
            }
            
            if path.hasPrefix("/direct/") ||
               path.hasPrefix("/direct/inbox") ||
               path.hasPrefix("/direct/t/") {
                decisionHandler(.allow)
                return
            }
            
            if path.hasPrefix("/explore/people") ||
               path.hasPrefix("/explore/search") ||
               urlString.contains("/explore/tags") {
                decisionHandler(.allow)
                return
            }

            if path.contains("accounts/activity") ||
               path.contains("accounts/edit") ||
               path.hasPrefix("/accounts/") {
                decisionHandler(.allow)
                return
            }
            
            if urlString.contains("instagram.com") && 
               (path.contains("/notifications/") || urlString.contains("/accounts/")) {
                decisionHandler(.allow)
                return
            }
            
            if urlString.contains("instagram.com") && path.count > 1 && !path.hasPrefix("/p/") && !path.hasPrefix("/reel/") {
                let components = path.components(separatedBy: "/").filter { !$0.isEmpty }
                if components.count == 1 && !components[0].contains(".") {
                    decisionHandler(.allow)
                    return
                }
            }
            
            if path == "/" && navigationAction.navigationType == .other {
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
               urlString.contains("static.cdninstagram") ||
               url.scheme == "blob" ||
               url.scheme == "data" {
                decisionHandler(.allow)
                return
            }

            if path == "/" ||
               path.hasPrefix("/explore") ||
               path.hasPrefix("/reels") ||
               path.hasPrefix("/tv") {
                if urlString.contains("show_notifications=true") {
                    print("✅ Allowing home for notifications")
                    decisionHandler(.allow)
                    return
                }
                
                if !path.contains("accounts") && !path.contains("notifications") && !parent.isSignedOut {
                    print("🚫 Blocking feed/explore, redirecting to DMs")
                    if let dmURL = URL(string: "https://www.instagram.com/direct/inbox/") {
                        webView.load(URLRequest(url: dmURL))
                    }
                    decisionHandler(.cancel)
                    return
                }
            }
            
            if !urlString.contains("instagram.com") && !urlString.contains("facebook.com") && !urlString.contains("fbcdn") {
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
                
                const hideBackButton = () => {
                    const path = window.location.pathname;
                    
                    if (path === '/direct/inbox/' || path === '/direct/inbox') {
                        document.querySelectorAll('svg[aria-label="Back"], button[aria-label="Back"], a[aria-label="Back"]').forEach(el => {
                            const button = el.closest('button') || el.closest('a');
                            if (button) {
                                button.style.display = 'none';
                            }
                        });
                        
                        document.querySelectorAll('svg').forEach(svg => {
                            const ariaLabel = svg.getAttribute('aria-label') || '';
                            if (ariaLabel.toLowerCase().includes('back')) {
                                const parent = svg.closest('button') || svg.closest('a') || svg.parentElement;
                                if (parent) {
                                    parent.style.display = 'none';
                                }
                            }
                        });
                    } else if (path.startsWith('/direct/t/')) {
                        document.querySelectorAll('svg[aria-label="Back"], button[aria-label="Back"], a[aria-label="Back"]').forEach(el => {
                            const button = el.closest('button') || el.closest('a');
                            if (button) {
                                button.style.display = '';
                            }
                        });
                        
                        document.querySelectorAll('svg').forEach(svg => {
                            const ariaLabel = svg.getAttribute('aria-label') || '';
                            if (ariaLabel.toLowerCase().includes('back')) {
                                const parent = svg.closest('button') || svg.closest('a') || svg.parentElement;
                                if (parent) {
                                    parent.style.display = '';
                                }
                            }
                        });
                    }
                };
                
                const hideFeedOnNotifications = () => {
                    if (window.location.search.includes('show_notifications=true')) {
                        document.querySelectorAll('main, article, section').forEach(el => {
                            if (!el.querySelector('[role="dialog"]') && !el.closest('[role="dialog"]')) {
                                el.style.display = 'none';
                            }
                        });
                        
                        document.querySelectorAll('[role="main"]').forEach(main => {
                            const hasDialog = main.querySelector('[role="dialog"]');
                            if (!hasDialog) {
                                main.style.display = 'none';
                            }
                        });
                    }
                };
                
                hideNav();
                blockReelScroll();
                hideComments();
                hideBackButton();
                hideFeedOnNotifications();
                
                const observer = new MutationObserver(() => {
                    hideNav();
                    blockReelScroll();
                    hideComments();
                    hideBackButton();
                    hideFeedOnNotifications();
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
                            hideBackButton();
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
