from pymol import cmd
import pymol
from Tkinter import *
import os
import tkFileDialog
import tkMessageBox
import subprocess
import webbrowser
import time



def __init__(self):
    self.menuBar.addmenuitem('Plugin', 'command', 'enlighten', label='enlighten', command=lambda s=self: mainDialog())

# Diaglogue lables
class enlighten(Frame):
    def __init__(self, parent):
        Frame.__init__(self, parent)
        # Parent means the frame that is being used
        self.parent = parent  # This what calls the ezlig(root)
        #self.initUI()

        self.selection = ""
        self.pdb = ""

        # There are four frames in the window containing various buttons/dropdowns etc
        self.parent.title("Enlighten Tools")
        frame4 = Frame(self.parent)
        frame4.grid(row=0, column=0, sticky="nsew")
        self.fv = IntVar()
        self.fv.set(1)
        self.file = Checkbutton(frame4, text="Choose from file", command=self.selectoption1, variable=self.fv,
                                offvalue=0, onvalue=1)
        self.file.grid(row=0, column=0)
        self.file.select()
        self.sv = IntVar()
        self.sv.set(0)
        self.sel = Checkbutton(frame4, text="Choose from PyMOL object", command=self.selectoption2, variable=self.sv,
                               offvalue=0, onvalue=1)
        self.sel.grid(row=0, column=1)
        self.sel.deselect()

        # Now move onto frame one
        frame1 = Frame(self.parent)
        frame1.grid(row=1, column=0)
        lbl1 = Label(frame1, text="PDB file", width=12)
        lbl1.grid(row=0, column=0)
        self.entry1 = Entry(frame1)
        self.entry1.grid(row=0, column=1, columnspan=4, sticky=W + E)
        self.browserButton = Button(frame1, text="Browser", command=self.onOpenF)
        self.browserButton.grid(row=0, column=5, sticky="e")

        lbl2 = Label(frame1, text="Enlighten folder", width=12)
        lbl2.grid(row=1, column=0)
        self.enlightenpath = Entry(frame1)
        #self.enlightenpath.insert(END, '/Users/simonbennie/enlighten') #fixme
        self.enlightenpath.insert(0, os.environ.get('ENLIGHTEN', 'Please specify ENLIGHTEN home directory'))
        self.enlightenpath.grid(row=1, column=1, columnspan=4, sticky=W + E)
        enlightenButton = Button(frame1, text="Browser", command=self.onOpen)
        enlightenButton.grid(row=1, column=5, sticky="e")
        lbl3 = Label(frame1, text="AMBER folder", width=12)
        lbl3.grid(row=2, column=0)
        self.amberpath = Entry(frame1)
        self.amberpath.grid(row=2, column=1, columnspan=4, sticky=W + E)
        amberButton = Button(frame1, text="Browser", command=self.onOpenA)
        amberButton.grid(row=2, column=5, sticky="e")
        # This will auto find the amber installation from the environment variables
        self.amberpath.insert(0, os.environ.get('AMBERHOME', 'Please specify AMBER home directory'))

        lbl4 = Label(frame1, text="Output folder", width=12)
        lbl4.grid(row=3, column=0)
        self.workingpath = Entry(frame1)
        self.workingdir=os.getcwd() #pymol.externing.pwd()
        self.workingpath.insert(END,os.getcwd())  # Fixme
        self.workingpath.grid(row=3, column=1, columnspan=4, sticky=W + E)
        outputButton = Button(frame1, text="Browser", command=self.onOpenO)
        outputButton.grid(row=3, column=5, sticky="e")
        lbl5 = Label(frame1, text="Ligand Name", width=12)
        lbl5.grid(row=4, column=0)
        self.ligandname = Entry(frame1)
        self.ligandname.insert(END, 'Ligand name') # Fixme
        self.ligandname.grid(row=4, column=1)
        lbl6 = Label(frame1, text="Ligand Charge", width=12)
        lbl6.grid(row=4, column=2)
        self.ligandcharge = Entry(frame1)
        self.ligandcharge.insert(END, '-1')
        self.ligandcharge.grid(row=4, column=3)

        # Time steps for use in dynam
        lbl7 = Label(frame1, text="Time (ps)", width=12)
        lbl7.grid(row=5, column=2)
        self.entry7 = Entry(frame1)
        self.entry7.insert(END, '100')
        self.entry7.grid(row=5, column=3)
        self.nstlim = int(self.entry7.get())  # Convert to time steps variable


        # This is where frame two starts
        frame2 = Frame(self.parent)
        frame2.grid(row=2, column=0, sticky="nsew")
        # This next section constructs a box plus the scroll bar and reaction to user input.
        self.vsb = Scrollbar(frame2, orient="vertical", command=self.OnVsb)
        self.vsb.grid(row=0, column=2, sticky="ns")
        lbl7 = Label(frame2, text="List of objects", width=12)
        lbl7.grid(row=0, column=0)
        self.lb1 = Listbox(frame2, yscrollcommand=self.vsb.set)
        self.lb1.grid(row=0, column=1)
        self.lb1.bind("<MouseWheel>", self.OnMouseWheel)
        self.lb1.bind("<<ListboxSelect>>", self.OnSelect)
        objects=cmd.get_names("all")
        objects.extend(["Pick object"])
        for x in objects:
            self.lb1.insert(END, x)



        #link = Label(frame2, text="Enlighten home", fg="blue", cursor="hand2")
        #link.bind("<Button-1>", callback)

        # self.vsb.config(state=DISABLED)
        frame3 = Frame(self.parent)
        frame3.grid(row=5, column=0,columnspan=3, sticky="nsew")
        # Three lower buttons in the plugin
        self.prepButton = Button(frame3, text="RUN PREP", command=self.runprep)
        self.prepButton.grid(row=0, column=0, sticky="e")
        self.structButton = Button(frame3, text="RUN STRUCT", command=self.runstruct)
        self.structButton.grid(row=0, column=1, sticky="e")
        self.structButton.config(state=DISABLED)
        self.dynamButton = Button(frame3, text="RUN DYNAM", command=self.rundynam)
        self.dynamButton.grid(row=0, column=2, sticky="e")
        self.dynamButton.config(state=DISABLED)

        self.website = Button(frame3, text="Enlighten Website",fg="blue", command=self.callback)
        self.website.grid(row=0, column=4, padx=0,sticky="e")
    # This next section defines a series of dialogues that are opened according the the actions from above
    def onOpenF(self):
        pdb = tkFileDialog.askopenfilename()
        self.entry1.delete(0, 'end')
        self.entry1.insert(0, pdb)
        path = os.path.split(pdb)
        self.workingpath.delete(0, 'end')
        self.workingpath.insert(0, path[0])

    def onOpenA(self):
        amber = tkFileDialog.askdirectory()
        self.amberpath.delete(0, 'end')
        self.amberpath.insert(0, amber)

    def onOpenO(self):
        out = tkFileDialog.askdirectory()
        self.workingpath.delete(0, 'end')
        self.workingpath.insert(0, out)

    def onOpen(self):
        fold = tkFileDialog.askdirectory()
        self.enlightenpath.delete(0, 'end')
        self.enlightenpath.insert(0, fold)
        os.environ["ENLIGHTEN"] = str(fold)

    def OnVsb(self, *args):
        self.lb1.yview(*args) # Moves the scroll bar

    def OnMouseWheel(self, event):
        self.lb1.yview("scroll", event.delta, "units")

    # Saves the selection for use
    def OnSelect(self, val):
        sender = val.widget
        idx = sender.curselection()
        self.selection = self.lb1.get(idx)

    # Diables the option that are not valid for selection with the first two tick boxes
    def selectoption1(self):
        self.sel.toggle()
        if (self.fv.get() == 0):
            self.fv.set(1)
            self.sv.set(0)
            self.entry1.config(state="normal")
            self.browserButton.config(state="normal")
            self.lb1.config(state=DISABLED)
            self.lb1.delete(0, 'end')
            objects=cmd.get_names("all")
            objects.extend(["Pick object"])
            for x in objects:
                self.lb1.insert(END, x)
        else:
            self.fv.set(0)
            self.sv.set(1)
            self.entry1.config(state=DISABLED)
            self.browserButton.config(state=DISABLED)
            self.lb1.config(state="normal")
            # self.vsb.config(state="normal")
            self.lb1.delete(0, 'end')

            objects=cmd.get_names("all")
            objects.extend(["Pick object"])
            for x in objects:
                self.lb1.insert(END, x)

                # print self.fv.get()
                # print self.sv.get()

    def selectoption2(self):
        self.file.toggle()
        if (self.sv.get() == 0):
            self.fv.set(0)
            self.sv.set(1)
            self.entry1.config(state=DISABLED)
            self.browserButton.config(state=DISABLED)
            self.lb1.config(state="normal")
            self.lb1.delete(0, 'end')

            objects=cmd.get_names("all")
            objects.extend(["Pick object"])
            for x in objects:
                self.lb1.insert(END, x)
        else:
            self.sv.set(0)
            self.fv.set(1)
            self.entry1.config(state="normal")
            self.browserButton.config(state="normal")
            self.lb1.config(state=DISABLED)
            # self.vsb.config(state="normal")
            self.lb1.delete(0, 'end')
            objects=cmd.get_names("all")
            objects.extend(["Pick object"])
            for x in objects:
                self.lb1.insert(END, x)

                # print self.fv.get()
                # print self.sv.get()
    def callback(event):
        #Open link to enlighten
        webbrowser.open_new("https://github.com/marcvanderkamp/enlighten/")


    def runprep(self):



        pymol.cmd.set("pdb_use_ter_records", "off")
        print("Setting the enlighten path to %s" % self.enlightenpath.get())
        os.environ["ENLIGHTEN"] = self.enlightenpath.get()
        if self.fv.get() == 1:
            if self.ligandname.get() == "Ligand name" or len(self.entry1.get()) == 0:
                tkMessageBox.showinfo("Error","Error missing ligand name or object")
                return
            os.chdir(self.workingpath.get())
            os.environ["AMBERHOME"] = self.amberpath.get()
            # Saves the command for use
            command = self.enlightenpath.get() + "/prep.sh " + os.path.basename(
                self.entry1.get()) + " " + self.ligandname.get() + " " + self.ligandcharge.get()
            #Executes the command passed above
            p = subprocess.Popen([command], shell=True, stderr=subprocess.PIPE)
            # This intiates a wait for the output to complete before the next stage is run
            while True:
                output = p.stdout.read(1)
                if output == '' and p.wait() != None:
                    break
                if output != '':
                    sys.stdout.write(output)
                    sys.stdout.flush()

            error = p.stderr.read()
            sys.stdout.write(error)
            sys.stdout.flush()
            path = os.path.split(self.entry1.get())
            temp = path[1].split('.')
            # First loads the topology file
            pymol.cmd.load("./" + temp[0] + "/" + temp[0] + ".sp20.top", temp[0] + ".sp20")
            # Loads the pdb
            pymol.cmd.load("./" + temp[0] + "/" + temp[0] + ".sp20.pdb", temp[0] + ".sp20")
            self.pdb = os.path.basename(self.entry1.get())
        # The difference between this and obe is the entry selection
        if self.sv.get() == 1:
            if self.ligandname.get() == "Ligand name" or len(self.selection) == 0:
                print(type(self.entry1.get()), len(self.entry1.get()))
                tkMessageBox.showinfo("Error","Error missing ligand name or object")
                return
            os.chdir(self.workingpath.get())
            print(os.chdir(self.workingpath.get()))
            cmd.save(self.workingpath.get() + "/" + self.selection + ".pdb", self.selection)
            os.environ["AMBERHOME"] = self.amberpath.get()
            os.environ["PATH"] = os.environ["PATH"] + ":" + os.environ["AMBERHOME"] + "/bin"
            command = self.enlightenpath.get() + "/prep.sh " + self.selection + ".pdb" + " " + self.ligandname.get() +\
                      " " + self.ligandcharge.get()
            p = subprocess.Popen([command], shell=True, stderr=subprocess.PIPE,stdout=subprocess.PIPE)
            while True:
                output = p.stdout.read(1)
                if output == '' and p.wait() != None:
                    break
                if output != '':
                    sys.stdout.write(output)
                    sys.stdout.flush()

            error = p.stderr.read()
            sys.stdout.write(error)
            sys.stdout.flush()



            temp = self.selection
            pymol.cmd.load("./" + temp + "/" + temp + ".sp20.top", temp + ".sp20")
            pymol.cmd.load("./" + temp +"/" + temp +  ".sp20.pdb", temp + ".sp20") # fixme
            self.pdb = self.selection + ".pdb"
        self.structButton.config(state="normal")

    def runstruct(self):
        os.environ["ENLIGHTEN"] = self.enlightenpath.get()
        command = self.enlightenpath.get() + "/struct/struct.sh " + self.pdb + " " + self.ligandname.get() +\
                  " " + self.ligandcharge.get()
        self.config(cursor="clock")
        self.update()
        p = subprocess.Popen([command], shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
        while True:
            output = p.stdout.read(1)
            if output == '' and p.wait() != None:
                break
            if output != '':
                sys.stdout.write(output)
                sys.stdout.flush()

            self.parent.update()
        self.config(cursor="")
        error = p.stderr.read()
        sys.stdout.write(error)
        sys.stdout.flush()

        temp = self.pdb[:-4]
        pymol.cmd.load("./" + temp +"/"+ temp + ".sp20.rst", temp + ".sp20")
        self.dynamButton.config(state="normal")
        print "Job Finished"

    # Run a dynamics calculation on the given structure
    # - heat.i: Brief heating(only 5 ps MD), meant to run with output from struct.sh (min_sa_ *.rst).
    # - md.i: 100 ps NVT MD, to follow heat.i.Writes and keeps restart files every 25 ps(12500 steps).
    # - min.i: Brief minimization(optionally performed after md.i).
    def rundynam(self):
        # heating command
        print(self.pdb)
        #self.top=temp+".sp20.top"
        #self.rst=temp+".sp20.rst"
        print(self.ligandname.get())
        belly=self.ligandname.get()
        temp = self.pdb[:-4]
        print("The dynam will run in three seperate parts, the first is quick, the second slow and the third is quick")
        told=time.time()
        command = self.enlightenpath.get() + "/dynam/sphere/dynam.sh " + self.pdb+ " "+ belly + " " + str(self.nstlim)
        p = subprocess.Popen([command], shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
        #print("Doing the heating step (short)")
        self.parent.update()
        while True:
            #if os.path.isfile("./" + temp + "/dynam/md_"+temp+".sp20.log"):
            #    print("Doing the dynamics step (long")
            #if os.path.isfile("./" + temp + "/dynam/min_"+temp+".sp20.log"):
            #    print("Doing the minimisation step (short")
            tnew=time.time()
            tdel = tnew-told
            if tdel > 20:
                told=tnew
                if os.path.isfile("./" + temp + "/dynam/mdinfo"):
                   for line in open("./" + temp + "/dynam/mdinfo"):
                       if "Estimated time " in line:
                            sys.stdout.write(line)
                            sys.stdout.flush()
            if p.poll() is not None:
                break
            self.parent.update()
        error = p.stderr.read()
        sys.stdout.write(error)
        sys.stdout.flush()
       # dynamm(self.amberpath.get(),self.top,self.rst,self.nstlim,belly)
        pymol.cmd.load("./" + temp + "/dynam/md_" + temp + ".sp20.trj", temp+".sp20",3,"trj")
        pymol.cmd.load("./" + temp + "/dynam/min_" + temp + ".sp20.rst", temp+".sp20")

def mainDialog():
    # Tk is a tinker python gui library, This is the default toolkit used in pymol
    root = Tk()
    root.resizable(0, 0)  # currently not resizable due to lack of reflow
    enlighten(root)  # This is where the enlighten class is called, passes the parent frame
    root.mainloop()