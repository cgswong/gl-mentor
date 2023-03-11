//*********************************************************************************************************************
// This Lambda script will act as the backend for a application load balancer
//
// Create the LB and TG as usual but in the TG select the lambda as the backend and pick this function
// from the dropdown. Also you need to enable the healthcheck else the lambda will never turn healthy
// If you are using the path based routing in LB then use /lambda as the path. Slash is important
//*********************************************************************************************************************

//Async is needed else the lambda complains that the response is not formatted well
exports.handler = async (event) => {
    console.log('Lambda is called from LB and the payload is');
    console.log(JSON.stringify(event));
    const response = {
        statusCode: 200,
        statusDescription: "200 OK",
        isBase64Encoded: false,
        headers: {
            "Content-Type": "text/html"
        },
        body: "<h1>Response from lambda web backend</h1>"
    };
    return response;
};

