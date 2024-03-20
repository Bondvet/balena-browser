let loaded = false;
let iframe;
let count = 0;

function onReady() {
    if (iframe) {
        iframe.parentNode.removeChild(iframe);
    }

    iframe = document.createElement('iframe');
    iframe.id = 'iframe';
    const url = decodeURIComponent(location.search.replace(/^\?url=/, ''));
    iframe.src = url;
    iframe.setAttribute('allow', 'fullscreen');
    iframe.addEventListener('load', iframeLoaded);

    document.body.appendChild(iframe);

    function onMessage(event) {
        if (event.data === 'loaded') {
            const origin = new URL(event.origin);
            const src = new URL(url);

            if (event.isTrusted && origin.origin === src.origin) {
                loaded = true;
            }
        }
    }

    window.addEventListener('message', onMessage, false);
}

function iframeLoaded() {
    const seconds = Math.min((2 ** count), 30);
    setTimeout(() => {
        if (loaded) {
            count = 0;
        } else {
            // something went wrong => try reloading
            onReady();
        }
    }, 500 + seconds * 1000);
    count += 1;
}


document.addEventListener('DOMContentLoaded', onReady);
