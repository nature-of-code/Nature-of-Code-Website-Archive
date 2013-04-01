//VALIDATE MEMBERSHIP
function validate_application(formObj) {
        warning = "";
        if(check_email(formObj.email.value) == false){
                warning += "\n - Valid e-mail address";
        }
        //Checks for errors from above
        if (warning != "") {
        alert("ERROR:  The form cannot be submitted because\nthe following fields are incomplete or invalid:\n" + warning);
                return false;
        }
        formObj.submit();
}
function check_email(email_address){
        var r1 = new RegExp("(@.*@)|(\\.\\.)|(@\\.)|(^\\.)");
        var r2 = new RegExp("^.+\\@(\\[?)[a-zA-Z0-9\\-\\.]+\\.([a-zA-Z]{2,4}|[0-9]{1,3})(\\]?)$");
        if (!r1.test(email_address) && r2.test(email_address)){ // We have good submission
        return true;
        }
        else{ // We have bad e-mail
        //warning += "\n - Valid e-mail";
        return false;
        }

}
