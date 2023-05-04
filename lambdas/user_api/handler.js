const responses = {
  "/dummy1": {
    message: "Dummy1 response"
  },
  "/dummy2": {
    message: "Dummy2 response"
  }
};

exports.handler = async (event) => {
  const path = event.path;

  if (responses[path]) {
    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(responses[path])
    };
  } else {
    return {
      statusCode: 404,
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        message: "Not found"
      })
    };
  }
};
