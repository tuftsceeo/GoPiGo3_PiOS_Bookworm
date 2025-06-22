<?php
  $ethcommand = "ifconfig eth0 | grep 'inet ' | cut -d' ' -f10";
  exec($ethcommand, $output, $return_var);
  if (strlen($output[0]) > 0) {
    $eth_ip = $output[0];
  } else {
    $eth_ip = "";
  }
  $wlan0command = "ifconfig wlan0 | grep 'inet ' | cut -d' ' -f10";
  exec($wlan0command, $wlan0output, $return_var);
  if (strlen($wlan0output[0]) > 0) {
    $wlan0_ip = $wlan0output[0];
  } else {
    $wlan0_ip = "";
  }
  $dexhost = $_SERVER['HTTP_HOST'];
  $dexhostname = file_get_contents('./hostname', true)
?>
<html>
<head>
    <title>GoPiGo Home for Tufts</title>
    <link rel="stylesheet" href="css/main_buster.css">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta http-equiv="cache-control" content="max-age=0" />
    <meta http-equiv="cache-control" content="no-cache" />
    <meta http-equiv="expires" content="0" />
    <meta http-equiv="expires" content="Tue, 01 Jan 1980 1:00:00 GMT" />
    <meta http-equiv="pragma" content="no-cache" />
</head>

<body>
  <div class="main-container">
        <div class="main wrapper clearfix">
  <header>
    
    <a href="https://ceeo.tufts.edu/" target="_blank">
      <img src="img/EDL Banners.png" onerror="this.src='img/EDL Banners.png'; this.onerror=null;"style="width:700px;">
    </a>
    
    <h1>EDL Software</h1>
  </header>

<article>
<section>
  <p>
    Welcome to the EDL for Robots OS v.25.1, our custom software for your GoPiGo Robots!
  </p>
  <p>
    To get started programming your robot, we will go through Jupyter Labs. an interactive textbook with programming built-in. 
  </p>
 <p>
    The workshop's Canvas page has more information.
</p>
  
</section>

<div class="mydiv">
  <section class="canvas">
    <a href="https://canvas.tufts.edu/courses/" target="_blank">
      <img src="img/canvas-logo.svg" onerror="this.src='img/canvas-logo.png'; this.onerror=null;"style="width:170px;">
      <span class="button">Open Canvas</span>
    </a>
  </section>
  
   <section class="jupyter">
    <a href="http://<?php echo $dexhost; ?>:8090" target="_blank">
      <img src="img/Jupyter_logo.svg" onerror="this.src='img/Jupyter_logo.svg'; this.onerror=null;"style="width:170px;">
      <span class="button">Launch JupyterLab</span>
    </a>
  </section>
</div>

<h1 class="divheader">Additional Utilities</h1>
<p>
    Below are additional tools, such as the Desktop Viewer through VNC (virtual network connections) which will show you a little desktop in your browser with icons and folders. Use these tools if you are aksed to by a TA or instructor, or if you are comfortable with GoPiGo and the command line.
  </p>
  
  

<div class="mydiv">
  <section class="vnc">
    <a href=" http://<?php echo $dexhost; ?>:6080/vnc.html?autoconnect=true&scaleViewport=true" target="_blank">
      <img src="img/viewer.svg" onerror="this.src='img/viewer.png'; this.onerror=null;"style="width:90px;">
      <span class="button">Launch Desktop (VNC)</span>
    </a>
      <em>Password: <strong>robots1234</strong></em>
  </section>
  
    <section class="bash">
    <a href="http://<?php echo $dexhost; ?>:4200" target="_blank">
      <img src="img/bash.svg" onerror="this.src='img/bash.png'; this.onerror=null;"style="width:90px;">
      <span class="button">Launch Terminal</span>
    </a>
      <em>
        Username: <strong>pi</strong>
        <br/>
        Password: <strong>robots1234</strong>
    </em>
  </section>
  
</div>

<h1 class="divheader">Robot Information</h1>
<div class="mydiv">
     <section class="gpgos">
    <a href="http://<?php echo $dexhost; ?>:100" target="_blank" style="cursor: default;">
      <img src="img/GoPiGo_logo.png" onerror="this.src='img/GoPiGo_logo.png'; this.onerror=null;"style="height:90px;">
    </a>
  </section>
<section class="IP">
<?php
$dexip = "";
foreach ($ips as &$ip) {
   $dexip = $dexip + $ip;
}
?>
    <ul>
        <li>Robot hostname : <?php echo $dexhostname; ?> </li>
        <?php if (strlen($wlan0_ip) > 0 ) { ?>
        <li>Robot WiFi IP address : <?php echo $wlan0_ip; ?> </li>
        <?php } ?>
        <?php if (strlen($eth_ip) > 0 ) { ?>
        <li>Robot ethernet IP address : <?php echo $eth_ip; ?> </li>
        <?php } ?>
  </ul>
</section>

</div>
<footer>
<h3>Need more help?</h3>

	<ul>
		<li>See more about the <a href="https://gopigo.io/support/" target="_blank" class="product gopigo">GoPiGo.</a></li>
	</ul>
  <p>
    This tool is based on <a href="https://github.com/DexterInd/Raspbian_For_Robots" target="_blank">Rasbian for Robots v10</a> developed by Dexter Industries and <a href="https://gopigo.io/gopigo-os-v-3-0-3/">GoPiGo OS 3.0.3</a> from Modular Robotics. 
  </p>
  <a href="http://www.dexterindustries.com/" target="_blank">
       <img src="img/dexter-logo-sm.png" class="standard logo" alt="Dexter Industries!" >
       <img src="img/dexter-logo-retina.png" class="retina logo" alt="Dexter Industries!" >
   </a>
  
</footer>
</article>
</div> <!-- #main -->
</div> <!-- #main-container -->

</body>
</html>

