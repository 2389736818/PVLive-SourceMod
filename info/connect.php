<?php
if (empty($_GET['host']))
    die('You need to specify your server\'s ip or url using "?host=yourserveraddresshere", if your server is not running on the default port for this game use "&port=yourserversporthere" after you specify your host.');
?>
<html lang="en">
<head>
<meta http-equiv="refresh" content="0; url=steam://connect/<?php echo $_GET['host'] . ':' . $_GET['port'];?>">
<script type="text/javascript">
function Return()
{
    setTimeout(GoBack, 100) //wait 1 second before continuing
}

function GoBack()
{
    if (document.referrer == "")
    {
        <?php if ($_GET['linkback']): ?>
		document.location.href = "<?php echo $_GET['linkback']?>"
		<?php else: ?>
		document.body.innerHTML = "This tab cannot close itself. Please close it. Or don't, I am a website, not a cop.";
		<?php endif; ?>
    }
    else
    {
        history.go(-1)
    }
}
</script>
</head>
<body onload="Return()">
    You should be automatically redirected shortly!
</body>
</html>