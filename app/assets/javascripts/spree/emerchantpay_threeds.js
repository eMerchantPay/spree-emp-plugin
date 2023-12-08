(function(document) {
    document.body.onload = function (){
        empThreedsSecureMethod('threedsMethodForm').execute()
    }
})(document);

const empThreedsSecureMethod = function(form_id) {
    let interval        = null
    let delay           = 500
    let retries         = 0
    let max_retries     = 12
    let status_complete = 'completed'
    let internal_error  = 'internal_error'

    // ThreedsForm HTML Element
    const threedsForm = function() {
        return document.getElementById(form_id)
    }

    // 3DSv2 Callback Status endpoint
    const getCallbackStatusUrl = function() {
        return threedsForm().dataset.statusUrl
    }

    // 3DSv2 Method Continue endpoint
    const getMethodContinueUrl = function() {
        return threedsForm().dataset.methodSecureUrl
    }

    const getFailureUrl = function() {
        return threedsForm().dataset.failureUrl
    }

    // Execute 3DSv2 submission
    const submitThreedsMethod = function(){
        threedsForm().submit()
        startLoop()
    }

    // 3DSv2 Secure Method Handler
    const startLoop = function() {
        initInterval(function() {
            checkCallbackStatus(function(data) {
                handleInternalError(data)

                if (retries >= max_retries || data.status === status_complete) {
                    clearInterval(interval)

                    sendBackEndData(function(data) {
                        handleInternalError(data)

                        redirectTo(data.redirect_url)
                    })
                }

                retries++;
            })
        })
    }

    const handleInternalError = function(data) {
        if (data.status === internal_error) {
            clearInterval(interval)
            redirectTo(getFailureUrl())
        }
    }

    // Redirect to the given url
    const redirectTo = function(url) {
        parent.location.href = url
    }

    // Initialize the Interval
    const initInterval = function(callback) {
        interval = setInterval(callback, delay)
    }

    // Check Callback status
    const checkCallbackStatus = function(callback) {
        ajaxCall(
            { method: 'GET', url: getCallbackStatusUrl(), async: false },
            (data) => { callback(data) },
            (status, response) => { callback({ status: internal_error }) }
        )
    }

    function sendBackEndData(callback) {
        ajaxCall(
            { method: 'POST', url: getMethodContinueUrl(), async: false, form_data: new FormData(threedsForm()) },
            (data) => { callback(data) },
            (status, response) => { callback({ status: internal_error }) }
        )
    }

    const ajaxCall = function(options, success, failure) {
        let xhr = new XMLHttpRequest()
        xhr.open(options.method, options.url, options.async)

        try {
            xhr.onload = function() {
                if (xhr.status === 200) {
                    return success(parseData(xhr.responseText))
                }

                return failure(xhr.status, xhr.responseText)
            };

            xhr.onerror = () => { failure(500, 'Network Error') }

            xhr.send(options.form_data)
        } catch(err) {
            failure(0, 'System error')
        }
    }

    const parseData = function(data) {
        try {
            return JSON.parse(data)
        } catch (error) {
            return {}
        }
    }


    return { execute: submitThreedsMethod }
};
