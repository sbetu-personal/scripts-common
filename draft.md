Below is an **example** of a minimal .drawio (diagrams.net) file that illustrates a scenario with:

- One **On-Premises** location  
- A **hub account** (with its own Direct Connect)  
- Two **application accounts** (each also with its own Direct Connect)  
- Each VPC has a **VGW** (Virtual Private Gateway) and a **VPC Peering** connection back to the hub VPC.  

This file is just a **basic starting point** to visualize what you’ve described. You can copy the XML below into a file (for example, `AWSMultiAccount.drawio`), then **Import** or **Open** it in [draw.io / diagrams.net](https://www.diagrams.net) or Visual Studio Code with a draw.io plugin. You’ll likely want to reposition shapes, rename them to match your real account IDs, etc.

---

## How to Use This File

1. **Copy all** of the XML text below.  
2. **Create** a new empty file on your local machine named `AWSMultiAccount.drawio` (or any name you like).  
3. **Paste** the XML into that file and **save**.  
4. **Open** [draw.io / diagrams.net](https://www.diagrams.net) in your browser (or use the desktop version).  
5. Choose **File** → **Open from** → **Device** → select the `.drawio` file you just saved.  
6. You should see a simple diagram with rectangles for On-Premises, Direct Connects, VGWs, and VPCs, along with connecting lines.

You can then edit shapes, add AWS icons, rename them, or move them around to fit your actual setup.

---

```xml
<?xml version="1.0" encoding="UTF-8"?>
<mxfile host="app.diagrams.net" modified="2025-03-26T12:00:00Z" agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64)" version="16.1.3" type="device">
  <diagram id="diagramId" name="AWS Multi-Account DC Setup">
    <mxGraphModel dx="1081" dy="754" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="827" pageHeight="1169" background="#FFFFFF">
      <root>
        <!-- Standard layer parents -->
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>

        <!-- On-Premises Node -->
        <mxCell id="2" value="On-Premises\n(Data Center)" style="shape=rectangle;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;strokeWidth=2" vertex="1" parent="1">
          <mxGeometry x="310" y="20" width="140" height="60" as="geometry"/>
        </mxCell>

        <!-- Hub Account DC -->
        <mxCell id="3" value="Hub DC Connection" style="shape=rectangle;whiteSpace=wrap;html=1;fillColor=#f8cecc;strokeColor=#b85450;strokeWidth=2" vertex="1" parent="1">
          <mxGeometry x="310" y="120" width="140" height="40" as="geometry"/>
        </mxCell>

        <!-- Hub VGW -->
        <mxCell id="4" value="Hub VGW" style="shape=rectangle;whiteSpace=wrap;html=1;fillColor=#ffe6cc;strokeColor=#d79b00;strokeWidth=2" vertex="1" parent="1">
          <mxGeometry x="310" y="190" width="140" height="40" as="geometry"/>
        </mxCell>

        <!-- Hub VPC -->
        <mxCell id="5" value="Hub VPC (vpcH)" style="shape=rectangle;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;strokeWidth=2" vertex="1" parent="1">
          <mxGeometry x="310" y="260" width="140" height="60" as="geometry"/>
        </mxCell>

        <!-- App #1 DC -->
        <mxCell id="6" value="App #1 DC Connection" style="shape=rectangle;whiteSpace=wrap;html=1;fillColor=#f8cecc;strokeColor=#b85450;strokeWidth=2" vertex="1" parent="1">
          <mxGeometry x="50" y="120" width="140" height="40" as="geometry"/>
        </mxCell>

        <!-- App #1 VGW -->
        <mxCell id="7" value="App #1 VGW" style="shape=rectangle;whiteSpace=wrap;html=1;fillColor=#ffe6cc;strokeColor=#d79b00;strokeWidth=2" vertex="1" parent="1">
          <mxGeometry x="50" y="190" width="140" height="40" as="geometry"/>
        </mxCell>

        <!-- App #1 VPC -->
        <mxCell id="8" value="App #1 VPC" style="shape=rectangle;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;strokeWidth=2" vertex="1" parent="1">
          <mxGeometry x="50" y="260" width="140" height="60" as="geometry"/>
        </mxCell>

        <!-- App #2 DC -->
        <mxCell id="9" value="App #2 DC Connection" style="shape=rectangle;whiteSpace=wrap;html=1;fillColor=#f8cecc;strokeColor=#b85450;strokeWidth=2" vertex="1" parent="1">
          <mxGeometry x="570" y="120" width="140" height="40" as="geometry"/>
        </mxCell>

        <!-- App #2 VGW -->
        <mxCell id="10" value="App #2 VGW" style="shape=rectangle;whiteSpace=wrap;html=1;fillColor=#ffe6cc;strokeColor=#d79b00;strokeWidth=2" vertex="1" parent="1">
          <mxGeometry x="570" y="190" width="140" height="40" as="geometry"/>
        </mxCell>

        <!-- App #2 VPC -->
        <mxCell id="11" value="App #2 VPC" style="shape=rectangle;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;strokeWidth=2" vertex="1" parent="1">
          <mxGeometry x="570" y="260" width="140" height="60" as="geometry"/>
        </mxCell>

        <!-- EDGES (Lines) -->

        <!-- On-Prem -> Hub DC -->
        <mxCell id="12" edge="1" parent="1" source="2" target="3" style="endArrow=classic;">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <!-- Hub DC -> Hub VGW -->
        <mxCell id="13" edge="1" parent="1" source="3" target="4" style="endArrow=classic;">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <!-- Hub VGW -> Hub VPC -->
        <mxCell id="14" edge="1" parent="1" source="4" target="5" style="endArrow=classic;">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>

        <!-- On-Prem -> App #1 DC -->
        <mxCell id="15" edge="1" parent="1" source="2" target="6" style="endArrow=classic;dashed=1;">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <!-- App #1 DC -> App #1 VGW -->
        <mxCell id="16" edge="1" parent="1" source="6" target="7" style="endArrow=classic;dashed=1;">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <!-- App #1 VGW -> App #1 VPC -->
        <mxCell id="17" edge="1" parent="1" source="7" target="8" style="endArrow=classic;">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>

        <!-- On-Prem -> App #2 DC -->
        <mxCell id="18" edge="1" parent="1" source="2" target="9" style="endArrow=classic;dashed=1;">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <!-- App #2 DC -> App #2 VGW -->
        <mxCell id="19" edge="1" parent="1" source="9" target="10" style="endArrow=classic;dashed=1;">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <!-- App #2 VGW -> App #2 VPC -->
        <mxCell id="20" edge="1" parent="1" source="10" target="11" style="endArrow=classic;">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>

        <!-- Peering: Hub VPC -> App #1 VPC -->
        <mxCell id="21" value="(pcx-...)" edge="1" parent="1" source="5" target="8" style="endArrow=open;strokeColor=#0000FF;">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>

        <!-- Peering: Hub VPC -> App #2 VPC -->
        <mxCell id="22" value="(pcx-...)" edge="1" parent="1" source="5" target="11" style="endArrow=open;strokeColor=#0000FF;">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>

      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

---

### What This Diagram Shows

1. **On-Premises** at the top, connecting to **three** “DC Connections”:
   - **Hub DC Connection** (middle)
   - **App #1 DC Connection** (left)
   - **App #2 DC Connection** (right)  
   (Dashed lines on the left/right just to visually distinguish them.)

2. Each AWS account’s VPC has:
   - A **VGW** connected to its own DC link.
   - A route from the VPC to its VGW for the default route to on-prem.

3. There’s a **VPC Peering** (in blue) from the **Hub VPC** to each “App VPC,” letting them communicate privately within AWS.

4. **No Transit Gateway** is shown, because you mentioned you’re not using RAM or TGW in your setup.

5. The presence of “Customer Gateways” (CGW) is not visually depicted here—if you have them, you could add them to represent Site-to-Site VPN endpoints.

You can **move**, **rename**, or **recolor** shapes once it’s open in draw.io, and add more text or icons as needed.

---

## Next Steps

1. **Open** this file in draw.io and tweak it to match your actual AWS account IDs, VPC CIDRs, and naming conventions.  
2. **Add** any leftover “Customer Gateways (cgw-xxxx)” if you want to show possible VPN tunnels.  
3. **Verify** the route tables in each VPC, ensuring the diagram matches reality (e.g., “0.0.0.0/0 → VGW” for each).  
4. **Share** with your network/architecture team to confirm the current design and discuss any consolidation or migrations.
