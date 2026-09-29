<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport" content="width=device-width, initial-scale=1.0">

<title>Login | EventSphere</title>

<link rel="stylesheet" href="css/login.css">

<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600&display=swap" rel="stylesheet">

</head>

<body>

<div class="login-box">

<h2>Welcome Back</h2>

<p>Login to EventSphere</p>

<form action="loginProcess.jsp" method="post">

<div class="input-box">

<label>Email</label>

<input type="email"
name="email"
placeholder="Enter Email"
required>

</div>

<div class="input-box">

<label>Password</label>

<input type="password"
name="password"
placeholder="Enter Password"
required>

</div>

<button type="submit">

Login

</button>

</form>

<p class="signup-text">

Don't have an account?

<a href="signup.jsp">Create Account</a>

</p>

</div>

</body>

</html>