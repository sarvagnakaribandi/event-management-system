<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html lang="en">

<head>

    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Sign Up | EventSphere</title>

    <link rel="stylesheet" href="css/signup.css">

    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">

</head>

<body>

<div class="container">

    <div class="signup-box">

        <h2>Create Account</h2>

        <p>Join EventSphere Today</p>

        <form action="register.jsp" method="post">

            <div class="input-box">

                <label>Full Name</label>

                <input type="text"
                       name="full_name"
                       placeholder="Enter Full Name"
                       required>

            </div>

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

            <div class="input-box">

                <label>Confirm Password</label>

                <input type="password"
                       name="confirm_password"
                       placeholder="Confirm Password"
                       required>

            </div>

            <div class="input-box">

                <label>Role</label>

                <select name="role">

                    <option>User</option>

                    <option>Organizer</option>

                </select>

            </div>

            <button type="submit">

                Create Account

            </button>

        </form>

        <p class="login-text">

            Already have an account?

            <a href="login.jsp">Login</a>

        </p>

    </div>

</div>

</body>

</html>